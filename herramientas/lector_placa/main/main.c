/*
 * herramientas/lector_placa/main/main.c — Lector HypokratIA en placa ESP32-S3
 *
 * Prueba 1: al enchufar la placa al PC por su puerto "USB", Windows la ve como
 * una tarjeta de red (USB NCM, sin instalar drivers). La placa le da una
 * dirección al PC (DHCP) y sirve una página en http://172.29.77.1
 *
 * v2: Windows 10 no cargaba solo el controlador de red ("USB net" con
 * triángulo amarillo). Se agrega el descriptor "Microsoft OS 2.0" (WINNCM),
 * igual que el ejemplo oficial de TinyUSB, para que Windows 10/11 use su
 * controlador de red USB incluido sin instalar nada. Además la dirección
 * pasa a 172.29.77.x (la anterior chocaba con routers como eero).
 *
 * No se ofrece "puerta de enlace" ni DNS: el PC sigue usando su internet
 * normal (si lo tiene) y solo habla con la placa en 172.29.77.x.
 *
 * Basado en el ejemplo de Espressif examples/network/sta2eth (usb_ncm_iface.c).
 * v3: la placa además es un teclado USB que abre la página sola.
 *
 * v4 (Lector completo, igual al Lector del PC 1.4, la app no cambia):
 *   · El lector queda siempre enchufado, sin ninguna página abierta.
 *   · Busca por Bluetooth los teléfonos que comparten su ficha ("HypokratIA"),
 *     se conecta solo (sin emparejar), intercambia llaves X25519 y todo va
 *     cifrado con AES-256-GCM (mismo protocolo que herramientas/lector_pc).
 *   · Cuando el paciente comparte, el lector abre solo la página de atención
 *     (la misma atencion.html del Lector del PC): en Windows con Windows+R →
 *     "msedge 172.29.77.1"; en Mac con Cmd+Espacio → Safari. Si la página ya
 *     está abierta, no escribe nada (la página cambia sola).
 *   · Código de 4 números en teléfono y página; el médico toca Aceptar.
 *   · La ficha vive solo en la memoria de la placa y se borra al terminar.
 *   · La página solo responde por la red USB (172.29.77.1) y con Host/Origin
 *     propios.
 *
 * v5: · Escribe mucho más rápido (el teclado informa cada 1 ms): la ventana
 *       "Ejecutar" apenas parpadea.
 *     · Se actualiza solo: http://172.29.77.1/actualizar → elegir el
 *       lector-placa.bin nuevo → listo (sin BOOT, RST ni ESP Tool). Solo
 *       sin una consulta en curso. Dos espacios de programa (ota_0/ota_1):
 *       si el nuevo no arranca, vuelve al anterior.
 * v7: · Dirección segura (https) para dictar: cada lector tiene su nombre
 *       (<id>.lector.hipokratia.health) y su llave P-256, que nunca sale del
 *       chip. El certificado (Let's Encrypt) lo pide y lo trae la app del
 *       paciente cuando tiene internet (/api/lector/certificado); el lector
 *       no necesita internet propio. Sin certificado todavía: http como antes.
 *     · El lector responde su propio nombre (DNS) para que funcione sin
 *       internet; cualquier otro nombre lo rechaza (el PC usa su DNS normal).
 *     · Permiso de consulta (transcribir / ordenar) que trae el teléfono:
 *       la página lo usa para "Ordenar con Claude" cuando el PC tiene internet.
 *
 * v6: · Solo acepta actualizaciones firmadas por HypokratIA (llave privada
 *       en el secreto LECTOR_FIRMA_KEY de GitHub; firma RSA-3072). Un archivo
 *       sin firma o firmado con otra llave se rechaza.
 *       Pendiente para fabricar: arranque seguro + memoria cifrada (nivel 2).
 */
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "esp_log.h"
#include "esp_event.h"
#include "esp_netif.h"
#include "esp_http_server.h"
#include "nvs_flash.h"
#include "tinyusb.h"
#include "tinyusb_net.h"
#include "dhcpserver/dhcpserver_options.h"
#include "lwip/esp_netif_net_stack.h"
#include "tusb.h"
#include "esp_random.h"
#include "esp_timer.h"
#include "cJSON.h"
#include "mbedtls/ecdh.h"
#include "mbedtls/hkdf.h"
#include "mbedtls/gcm.h"
#include "mbedtls/base64.h"
#include "mbedtls/md.h"
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "host/ble_hs.h"
#include "freertos/semphr.h"
#include "esp_ota_ops.h"
#include "esp_https_server.h"
#include "esp_mac.h"
#include "mbedtls/pk.h"
#include "mbedtls/x509_csr.h"
#include "mbedtls/x509_crt.h"
#include "mbedtls/sha256.h"
#include "lwip/sockets.h"
#include "nvs.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char *TAG = "lector";
static esp_netif_t *s_netif = NULL;

/* ── Identidad del lector: nombre, llave y certificado (NVS) ───────────── */

#define DOMINIO_LECTORES ".lector.hipokratia.health"
static char s_nombre[24];                 // p. ej. "k3x7q2m9ab"
static char s_dominio[64];                // p. ej. "k3x7q2m9ab.lector.hipokratia.health"
static char *s_llave_pem = NULL;          // PEM de la llave privada (P-256)
static char *s_cert = NULL;               // cadena PEM del certificado vigente (o NULL)
static int64_t s_cert_vence = 0;          // segundos Unix (notAfter)
static const char *s_cert_estado = "sin certificado";   // para /api/estado (diagnóstico)
static volatile bool s_cert_nuevo = false;   // se instaló uno nuevo: reiniciar al terminar la consulta

static int azar_id(void *p, unsigned char *buf, size_t n) { esp_fill_random(buf, n); return 0; }

static char *nvs_leer(const char *clave)
{
    nvs_handle_t h;
    if (nvs_open("lector", NVS_READONLY, &h) != ESP_OK) return NULL;
    size_t n = 0;
    char *v = NULL;
    if (nvs_get_str(h, clave, NULL, &n) == ESP_OK && n > 0) {
        v = malloc(n);
        if (v && nvs_get_str(h, clave, v, &n) != ESP_OK) { free(v); v = NULL; }
    }
    nvs_close(h);
    return v;
}

static esp_err_t nvs_guardar(const char *clave, const char *valor)
{
    nvs_handle_t h;
    esp_err_t r = nvs_open("lector", NVS_READWRITE, &h);
    if (r != ESP_OK) return r;
    r = nvs_set_str(h, clave, valor);
    if (r == ESP_OK) r = nvs_commit(h);
    nvs_close(h);
    return r;
}

// El certificado (cadena completa de Let's Encrypt) puede pasar los 4000
// bytes que acepta nvs_set_str: se guarda como blob (con su \0 final).
static esp_err_t nvs_guardar_blob(const char *clave, const char *valor)
{
    nvs_handle_t h;
    esp_err_t r = nvs_open("lector", NVS_READWRITE, &h);
    if (r != ESP_OK) return r;
    r = nvs_set_blob(h, clave, valor, strlen(valor) + 1);
    if (r == ESP_OK) r = nvs_commit(h);
    nvs_close(h);
    return r;
}

static char *nvs_leer_blob(const char *clave)
{
    nvs_handle_t h;
    if (nvs_open("lector", NVS_READONLY, &h) != ESP_OK) return NULL;
    size_t n = 0;
    char *v = NULL;
    if (nvs_get_blob(h, clave, NULL, &n) == ESP_OK && n > 1) {
        v = malloc(n);
        if (v && nvs_get_blob(h, clave, v, &n) != ESP_OK) { free(v); v = NULL; }
        if (v) v[n - 1] = 0;
    }
    nvs_close(h);
    return v;
}

static int64_t dias_desde_civil(int y, int m, int d)   // días desde 1970-01-01
{
    y -= m <= 2;
    int64_t era = (y >= 0 ? y : y - 399) / 400;
    int64_t yoe = y - era * 400;
    int64_t doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
    int64_t doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}

// Revisa que el certificado sea de ESTE lector (misma llave) y devuelve su vencimiento
static bool cert_valido(const char *pem, int64_t *vence)
{
    mbedtls_x509_crt crt;
    mbedtls_pk_context llave;
    mbedtls_x509_crt_init(&crt);
    mbedtls_pk_init(&llave);
    bool ok = mbedtls_x509_crt_parse(&crt, (const unsigned char *)pem, strlen(pem) + 1) == 0
           && mbedtls_pk_parse_key(&llave, (const unsigned char *)s_llave_pem, strlen(s_llave_pem) + 1,
                                   NULL, 0, azar_id, NULL) == 0
           && mbedtls_pk_check_pair(&crt.pk, &llave, azar_id, NULL) == 0;
    if (ok && vence) {
        const mbedtls_x509_time *t = &crt.valid_to;
        *vence = dias_desde_civil(t->year, t->mon, t->day) * 86400 + t->hour * 3600 + t->min * 60 + t->sec;
    }
    mbedtls_pk_free(&llave);
    mbedtls_x509_crt_free(&crt);
    return ok;
}

static void cargar_identidad(void)
{
    // Nombre: a partir de la MAC del chip (único por placa)
    uint8_t mac[6], h[32];
    esp_efuse_mac_get_default(mac);
    mbedtls_sha256(mac, 6, h, 0);
    static const char ALFA[] = "abcdefghijkmnpqrstuvwxyz23456789";
    for (int i = 0; i < 10; i++) s_nombre[i] = ALFA[h[i] % 32];
    s_nombre[10] = 0;
    snprintf(s_dominio, sizeof(s_dominio), "%s" DOMINIO_LECTORES, s_nombre);

    // Llave: se crea una sola vez, dentro del chip
    s_llave_pem = nvs_leer("llave");
    if (!s_llave_pem) {
        mbedtls_pk_context k;
        mbedtls_pk_init(&k);
        char *pem = malloc(1024);
        if (pem && mbedtls_pk_setup(&k, mbedtls_pk_info_from_type(MBEDTLS_PK_ECKEY)) == 0
                && mbedtls_ecp_gen_key(MBEDTLS_ECP_DP_SECP256R1, mbedtls_pk_ec(k), azar_id, NULL) == 0
                && mbedtls_pk_write_key_pem(&k, (unsigned char *)pem, 1024) == 0
                && nvs_guardar("llave", pem) == ESP_OK) {
            s_llave_pem = pem;
            ESP_LOGI(TAG, "Llave propia del lector creada");
        } else {
            free(pem);
        }
        mbedtls_pk_free(&k);
    }
    // Certificado: si hay uno y es de esta llave, se usa https
    if (s_llave_pem) {
        char *cert = nvs_leer_blob("certpem");
        if (!cert) cert = nvs_leer("cert");               // versiones anteriores
        if (cert && cert_valido(cert, &s_cert_vence)) { s_cert = cert; s_cert_estado = "ok"; }
        else { if (cert) s_cert_estado = "certificado guardado no sirve"; free(cert); }
    }
    ESP_LOGI(TAG, "Lector %s · %s", s_dominio, s_cert ? "con certificado (https)" : "sin certificado todavía (http)");
}

// Solicitud de certificado (CSR) para el nombre del lector
static char *crear_csr(void)
{
    if (!s_llave_pem) return NULL;
    mbedtls_pk_context k;
    mbedtls_x509write_csr req;
    mbedtls_pk_init(&k);
    mbedtls_x509write_csr_init(&req);
    char *pem = malloc(1200), sujeto[96];
    snprintf(sujeto, sizeof(sujeto), "CN=%s", s_dominio);
    bool ok = pem && mbedtls_pk_parse_key(&k, (const unsigned char *)s_llave_pem, strlen(s_llave_pem) + 1,
                                          NULL, 0, azar_id, NULL) == 0;
    if (ok) {
        mbedtls_x509write_csr_set_md_alg(&req, MBEDTLS_MD_SHA256);
        mbedtls_x509write_csr_set_key(&req, &k);
        ok = mbedtls_x509write_csr_set_subject_name(&req, sujeto) == 0
          && mbedtls_x509write_csr_pem(&req, (unsigned char *)pem, 1200, azar_id, NULL) == 0;
    }
    mbedtls_x509write_csr_free(&req);
    mbedtls_pk_free(&k);
    if (!ok) { free(pem); return NULL; }
    return pem;
}

// DNS mínimo: responde SOLO el nombre del lector; el resto se rechaza (REFUSED)
// para que el PC pregunte enseguida a su DNS normal.
static void tarea_dns(void *arg)
{
    int s = socket(AF_INET, SOCK_DGRAM, 0);
    struct sockaddr_in a = { .sin_family = AF_INET, .sin_port = htons(53), .sin_addr.s_addr = htonl(INADDR_ANY) };
    if (s < 0 || bind(s, (struct sockaddr *)&a, sizeof(a)) != 0) { ESP_LOGE(TAG, "DNS no disponible"); vTaskDelete(NULL); }
    uint8_t b[512];
    for (;;) {
        struct sockaddr_in de;
        socklen_t ld = sizeof(de);
        int n = recvfrom(s, b, sizeof(b), 0, (struct sockaddr *)&de, &ld);
        if (n < 12 || (b[2] & 0x80) || b[4] != 0 || b[5] != 1) continue;   // solo preguntas con 1 consulta
        char nombre[128];
        int i = 12, j = 0;
        while (i < n && b[i] && j < (int)sizeof(nombre) - 2) {
            int largo = b[i++];
            if (largo > 63 || i + largo > n) { j = -1; break; }
            if (j) nombre[j++] = '.';
            for (int k = 0; k < largo && j < (int)sizeof(nombre) - 1; k++) nombre[j++] = tolower(b[i++]);
        }
        if (j < 0 || i + 5 > n) continue;
        nombre[j] = 0;
        i++;                                                   // 0 final del nombre
        uint16_t tipo = b[i] << 8 | b[i + 1];
        int fin_pregunta = i + 4;
        bool nuestro = strcmp(nombre, s_dominio) == 0;
        b[2] = 0x80 | (b[2] & 0x79) | (nuestro ? 0x04 : 0);   // respuesta, AA si es nuestro, RD copiado
        b[3] = nuestro ? 0x00 : 0x05;                          // NOERROR / REFUSED
        b[6] = b[7] = b[8] = b[9] = b[10] = b[11] = 0;
        int largo_resp = fin_pregunta;
        if (nuestro && tipo == 1 && fin_pregunta + 16 <= (int)sizeof(b)) {
            b[7] = 1;                                          // 1 respuesta (A)
            uint8_t r[] = { 0xC0, 0x0C, 0, 1, 0, 1, 0, 0, 0, 60, 0, 4, 172, 29, 77, 1 };
            memcpy(b + fin_pregunta, r, sizeof(r));
            largo_resp += sizeof(r);
        }
        sendto(s, b, largo_resp, 0, (struct sockaddr *)&de, ld);
    }
}

/* ── Red USB (NCM) ↔ lwIP ─────────────────────────────────────────────── */

static void liberar_rx(void *h, void *buffer) { free(buffer); }

static esp_err_t enviar_al_pc(void *h, void *buffer, size_t len)
{
    if (tinyusb_net_send_sync(buffer, len, NULL, pdMS_TO_TICKS(100)) != ESP_OK) {
        ESP_LOGW(TAG, "No se pudo enviar al PC");
    }
    return ESP_OK;
}

static esp_err_t recibido_del_pc(void *buffer, uint16_t len, void *ctx)
{
    if (!s_netif) return ESP_OK;
    void *copia = malloc(len);
    if (!copia) return ESP_ERR_NO_MEM;
    memcpy(copia, buffer, len);
    return esp_netif_receive(s_netif, copia, len, NULL);
}

/* ── Descriptores USB: Windows carga su controlador de red sin instalar nada ── */

// Producto propio (PID nuevo: Windows guarda en memoria lo que vio de cada PID)
static const tusb_desc_device_t descriptor_equipo = {
    .bLength            = sizeof(tusb_desc_device_t),
    .bDescriptorType    = TUSB_DESC_DEVICE,
    .bcdUSB             = 0x0201,               // 2.01: el PC pide el descriptor BOS
    .bDeviceClass       = TUSB_CLASS_MISC,
    .bDeviceSubClass    = MISC_SUBCLASS_COMMON,
    .bDeviceProtocol    = MISC_PROTOCOL_IAD,
    .bMaxPacketSize0    = CFG_TUD_ENDPOINT0_SIZE,
    .idVendor           = 0x303A,               // Espressif
    .idProduct          = 0x4A01,               // Lector HypokratIA
    .bcdDevice          = 0x0300,               // cambia si cambian las interfaces
    .iManufacturer      = 0x01,
    .iProduct           = 0x02,
    .iSerialNumber      = 0x03,
    .bNumConfigurations = 0x01,
};

// Interfaces: red (2) + teclado (1)
enum { ITF_RED = 0, ITF_RED_DATOS, ITF_TECLADO, ITF_TOTAL };
enum { STR_IDIOMA = 0, STR_FABRICANTE, STR_PRODUCTO, STR_SERIE, STR_RED, STR_MAC, STR_TECLADO, STR_TOTAL };

// STR_MAC (5) lo llena el driver de red con la MAC: debe ser el mismo índice
// que usa esp_tinyusb (sin CDC ni MSC: idioma, fabricante, producto, serie, red, MAC)
static const char *textos_usb[STR_TOTAL] = {
    (char[]){0x09, 0x04}, "HypokratIA", "Lector HypokratIA", "HK0001",
    "Red del lector", "", "Teclado del lector",
};

static const uint8_t informe_teclado[] = { TUD_HID_REPORT_DESC_KEYBOARD() };

#define CONFIG_LARGO (TUD_CONFIG_DESC_LEN + TUD_CDC_NCM_DESC_LEN + TUD_HID_DESC_LEN)
static const uint8_t descriptor_config[] = {
    TUD_CONFIG_DESCRIPTOR(1, ITF_TOTAL, 0, CONFIG_LARGO, 0, 100),
    TUD_CDC_NCM_DESCRIPTOR(ITF_RED, STR_RED, STR_MAC, 0x81, 64, 0x02, 0x82, 64, CFG_TUD_NET_MTU),
    TUD_HID_DESCRIPTOR(ITF_TECLADO, STR_TECLADO, HID_ITF_PROTOCOL_KEYBOARD, sizeof(informe_teclado), 0x83, 8, 1),
};

uint8_t const *tud_hid_descriptor_report_cb(uint8_t instance) { return informe_teclado; }
uint16_t tud_hid_get_report_cb(uint8_t instance, uint8_t report_id, hid_report_type_t report_type,
                               uint8_t *buffer, uint16_t reqlen) { return 0; }
void tud_hid_set_report_cb(uint8_t instance, uint8_t report_id, hid_report_type_t report_type,
                           uint8_t const *buffer, uint16_t bufsize) {}
#define MS_OS_20_LARGO     0xB2
#define BOS_LARGO          (TUD_BOS_DESC_LEN + TUD_BOS_MICROSOFT_OS_DESC_LEN)

static const uint8_t descriptor_bos[] = {
    TUD_BOS_DESCRIPTOR(BOS_LARGO, 1),
    TUD_BOS_MS_OS_20_DESCRIPTOR(MS_OS_20_LARGO, 1),
};

uint8_t const *tud_descriptor_bos_cb(void) { return descriptor_bos; }

// "Microsoft OS 2.0": la interfaz de red usa el controlador WINNCM de Windows
static const uint8_t descriptor_ms_os_20[] = {
    U16_TO_U8S_LE(0x000A), U16_TO_U8S_LE(MS_OS_20_SET_HEADER_DESCRIPTOR), U32_TO_U8S_LE(0x06030000),
    U16_TO_U8S_LE(MS_OS_20_LARGO),
    U16_TO_U8S_LE(0x0008), U16_TO_U8S_LE(MS_OS_20_SUBSET_HEADER_CONFIGURATION), 0, 0,
    U16_TO_U8S_LE(MS_OS_20_LARGO - 0x0A),
    U16_TO_U8S_LE(0x0008), U16_TO_U8S_LE(MS_OS_20_SUBSET_HEADER_FUNCTION), ITF_RED, 0,
    U16_TO_U8S_LE(MS_OS_20_LARGO - 0x0A - 0x08),
    U16_TO_U8S_LE(0x0014), U16_TO_U8S_LE(MS_OS_20_FEATURE_COMPATBLE_ID), 'W', 'I', 'N', 'N', 'C', 'M', 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    U16_TO_U8S_LE(MS_OS_20_LARGO - 0x0A - 0x08 - 0x08 - 0x14), U16_TO_U8S_LE(MS_OS_20_FEATURE_REG_PROPERTY),
    U16_TO_U8S_LE(0x0007), U16_TO_U8S_LE(0x002A),
    'D', 0, 'e', 0, 'v', 0, 'i', 0, 'c', 0, 'e', 0, 'I', 0, 'n', 0, 't', 0, 'e', 0, 'r', 0,
    'f', 0, 'a', 0, 'c', 0, 'e', 0, 'G', 0, 'U', 0, 'I', 0, 'D', 0, 's', 0, 0, 0,
    U16_TO_U8S_LE(0x0050),
    '{', 0, '4', 0, 'B', 0, '7', 0, 'A', 0, '1', 0, 'C', 0, '0', 0, '2', 0, '-', 0, '5', 0,
    'E', 0, '3', 0, 'D', 0, '-', 0, '4', 0, 'F', 0, '1', 0, 'A', 0, '-', 0, '9', 0, 'C', 0,
    '6', 0, 'B', 0, '-', 0, '2', 0, 'D', 0, '8', 0, 'E', 0, '4', 0, 'F', 0, '7', 0, '1', 0,
    'A', 0, '9', 0, 'C', 0, '3', 0, '}', 0, 0, 0, 0, 0,
};
_Static_assert(sizeof(descriptor_ms_os_20) == MS_OS_20_LARGO, "largo MS OS 2.0");

// Solo Windows pide este descriptor: así el lector sabe qué atajo usar para abrir la página
static volatile bool s_es_windows = false;

bool tud_vendor_control_xfer_cb(uint8_t rhport, uint8_t stage, tusb_control_request_t const *req)
{
    if (stage != CONTROL_STAGE_SETUP) return true;
    if (req->bmRequestType_bit.type == TUSB_REQ_TYPE_VENDOR && req->bRequest == 1 && req->wIndex == 7) {
        s_es_windows = true;
        return tud_control_xfer(rhport, req, (void *)(uintptr_t)descriptor_ms_os_20, MS_OS_20_LARGO);
    }
    return false;
}

static esp_err_t iniciar_red_usb(void)
{
    const tinyusb_config_t tusb_cfg = {
        .device_descriptor = &descriptor_equipo,
        .string_descriptor = textos_usb,
        .string_descriptor_count = STR_TOTAL,
        .configuration_descriptor = descriptor_config,
        .external_phy = false,
    };
    ESP_ERROR_CHECK(tinyusb_driver_install(&tusb_cfg));

    const tinyusb_net_config_t net_cfg = {
        .mac_addr = {0x02, 0x48, 0x4B, 0x00, 0x00, 0x01},   // tarjeta que ve el PC
        .on_recv_callback = recibido_del_pc,
    };
    ESP_ERROR_CHECK(tinyusb_net_init(TINYUSB_USBDEV_0, &net_cfg));

    static const esp_netif_ip_info_t ip = {
        .ip      = { .addr = ESP_IP4TOADDR(172, 29, 77, 1) },
        .gw      = { .addr = ESP_IP4TOADDR(172, 29, 77, 1) },
        .netmask = { .addr = ESP_IP4TOADDR(255, 255, 255, 0) },
    };
    esp_netif_inherent_config_t base = {
        .flags = ESP_NETIF_DHCP_SERVER | ESP_NETIF_FLAG_AUTOUP,
        .ip_info = &ip,
        .if_key = "lector_usb",
        .if_desc = "lector hypokratia usb",
        .route_prio = 10,
    };
    esp_netif_driver_ifconfig_t driver = {
        .handle = (void *)1,
        .transmit = enviar_al_pc,
        .driver_free_rx_buffer = liberar_rx,
    };
    struct esp_netif_netstack_config pila = {
        .lwip = { .init_fn = ethernetif_init, .input_fn = ethernetif_input },
    };
    esp_netif_config_t cfg = { .base = &base, .driver = &driver, .stack = &pila };

    s_netif = esp_netif_new(&cfg);
    if (!s_netif) return ESP_FAIL;
    uint8_t mac_placa[6] = {0x02, 0x48, 0x4B, 0x00, 0x00, 0x02};
    esp_netif_set_mac(s_netif, mac_placa);

    // Sin puerta de enlace ni DNS: el PC no manda su internet por la placa
    uint8_t sin_router = 0;   // dhcps_offer_t: 0 = no ofrecer router
    esp_netif_dhcps_option(s_netif, ESP_NETIF_OP_SET, ESP_NETIF_ROUTER_SOLICITATION_ADDRESS,
                           &sin_router, sizeof(sin_router));
    if (s_cert) {
        // El nombre del lector se resuelve aquí, aunque no haya internet
        esp_netif_dns_info_t dns = { .ip.u_addr.ip4.addr = ESP_IP4TOADDR(172, 29, 77, 1), .ip.type = ESP_IPADDR_TYPE_V4 };
        esp_netif_set_dns_info(s_netif, ESP_NETIF_DNS_MAIN, &dns);
        uint8_t ofrecer_dns = 0x02;   // OFFER_DNS
        esp_netif_dhcps_option(s_netif, ESP_NETIF_OP_SET, ESP_NETIF_DOMAIN_NAME_SERVER,
                               &ofrecer_dns, sizeof(ofrecer_dns));
    }
    uint32_t arriendo = 120;   // minutos
    esp_netif_dhcps_option(s_netif, ESP_NETIF_OP_SET, IP_ADDRESS_LEASE_TIME,
                           &arriendo, sizeof(arriendo));

    esp_netif_action_start(s_netif, 0, 0, 0);
    ESP_LOGI(TAG, "Red USB lista: http://172.29.77.1");
    return ESP_OK;
}

/* ── Teclado: abre la página sola ─────────────────────────────────────── */

#define VERSION        "placa-2.1"
#define DIRECCION      "172.29.77.1"

static volatile bool s_pc_con_direccion = false;
static volatile int64_t s_ultimo_sondeo = 0;     // la página abierta consulta /api/estado cada 1 s
static volatile bool s_abriendo = false;

static void pc_recibio_direccion(void *arg, esp_event_base_t base, int32_t id, void *datos)
{
    s_pc_con_direccion = true;
}

static void tecla(uint8_t modificador, uint8_t codigo)
{
    uint8_t teclas[6] = { codigo, 0, 0, 0, 0, 0 };
    for (int i = 0; i < 100 && !tud_hid_ready(); i++) vTaskDelay(1);
    tud_hid_keyboard_report(0, modificador, teclas);
    for (int i = 0; i < 100 && !tud_hid_ready(); i++) vTaskDelay(1);
    tud_hid_keyboard_report(0, 0, NULL);
}

// Solo minúsculas, números, punto y espacio (misma tecla en teclado español e inglés)
static void escribir(const char *texto)
{
    for (const char *c = texto; *c; c++) {
        uint8_t k = 0;
        if (*c >= 'a' && *c <= 'z') k = HID_KEY_A + (*c - 'a');
        else if (*c >= '1' && *c <= '9') k = HID_KEY_1 + (*c - '1');
        else if (*c == '0') k = HID_KEY_0;
        else if (*c == '.') k = HID_KEY_PERIOD;
        else if (*c == ' ') k = HID_KEY_SPACE;
        if (k) tecla(0, k);
    }
}

static void tarea_abrir_pagina(void *arg)
{
    if (s_es_windows) {
        ESP_LOGI(TAG, "Abriendo la página (Windows)");
        tecla(KEYBOARD_MODIFIER_LEFTGUI, HID_KEY_R);          // Ejecutar
        vTaskDelay(pdMS_TO_TICKS(400));
        char orden[96];
        snprintf(orden, sizeof(orden), "msedge %s", s_cert ? s_dominio : DIRECCION);
        escribir(orden);
        tecla(0, HID_KEY_ENTER);
    } else {
        ESP_LOGI(TAG, "Abriendo la página (Mac)");
        tecla(KEYBOARD_MODIFIER_LEFTGUI, HID_KEY_SPACE);      // Spotlight
        vTaskDelay(pdMS_TO_TICKS(700));
        escribir("safari");
        vTaskDelay(pdMS_TO_TICKS(300));
        tecla(0, HID_KEY_ENTER);
        vTaskDelay(pdMS_TO_TICKS(2500));
        tecla(KEYBOARD_MODIFIER_LEFTGUI, HID_KEY_N);          // ventana nueva (dirección lista para escribir)
        vTaskDelay(pdMS_TO_TICKS(800));
        escribir(s_cert ? s_dominio : DIRECCION);
        vTaskDelay(pdMS_TO_TICKS(100));
        tecla(0, HID_KEY_ENTER);
    }
    s_abriendo = false;
    vTaskDelete(NULL);
}

// Se llama cuando un paciente comparte su ficha
static void abrir_pagina(void)
{
    bool pagina_abierta = (esp_timer_get_time() - s_ultimo_sondeo) < 4000000;
    if (pagina_abierta || s_abriendo) return;                 // la página cambia sola
    if (!tud_mounted() || !s_pc_con_direccion) {
        ESP_LOGW(TAG, "El PC todavía no tiene la red del lector");
        return;
    }
    s_abriendo = true;
    xTaskCreate(tarea_abrir_pagina, "abrir_pagina", 4096, NULL, 5, NULL);
}

/* ── Cifrado (igual que lector_pc/lector.py) ─────────────────────────── */

static const uint8_t SAL[] = "hipokratia-lector-1";      // sin el 0 final
#define SAL_LARGO (sizeof(SAL) - 1)

static int azar(void *p, unsigned char *buf, size_t n) { esp_fill_random(buf, n); return 0; }

static char *b64(const uint8_t *d, size_t n)
{
    size_t largo = 0;
    mbedtls_base64_encode(NULL, 0, &largo, d, n);
    char *out = malloc(largo + 1);
    if (!out) return NULL;
    mbedtls_base64_encode((unsigned char *)out, largo + 1, &largo, d, n);
    out[largo] = 0;
    return out;
}

static uint8_t *de_b64(const char *t, size_t *n)
{
    size_t largo = 0;
    mbedtls_base64_decode(NULL, 0, &largo, (const unsigned char *)t, strlen(t));
    uint8_t *out = malloc(largo ? largo : 1);
    if (!out) return NULL;
    if (mbedtls_base64_decode(out, largo, n, (const unsigned char *)t, strlen(t)) != 0) { free(out); return NULL; }
    return out;
}

/* ── La consulta (una a la vez) ──────────────────────────────────────── */

typedef enum { E_NINGUNA = 0, E_HANDSHAKE, E_SOLICITUD, E_ACEPTADA, E_ACTIVA } estado_t;
static const char *NOMBRE_ESTADO[] = { "espera", "espera", "solicitud", "aceptada", "activa" };

static struct {
    estado_t estado;
    uint16_t conn;
    mbedtls_ecp_group grupo;
    mbedtls_mpi privada;
    mbedtls_ecp_point publica;
    uint8_t clave[32];
    bool con_clave;
    char codigo[5];
    char paciente[96];
    char *permiso;            // permiso de consulta (transcribir / ordenar), si el teléfono tenía internet
    bool pidio_certificado;
    char *ficha;              // JSON de la ficha (solo en memoria)
    bool nota_guardada;       // una atención por consulta
    int sec;
    int esperando;            // número de la confirmación que se espera
    cJSON *respuesta;
} S;
static volatile int64_t s_estado_desde = 0;   // cuándo entró la consulta a su estado actual (µs)

static SemaphoreHandle_t g_mutex, g_resp, g_tx, g_escrito;
static volatile int g_escrito_estado;
static uint16_t g_rx_handle, g_tx_handle;

static void terminar_sesion(bool desconectar);

/* Envío por Bluetooth: [4 bytes largo][JSON], en trozos del tamaño que permite el enlace */
static int al_escribir(uint16_t conn, const struct ble_gatt_error *err, struct ble_gatt_attr *attr, void *arg)
{
    g_escrito_estado = err->status;
    xSemaphoreGive(g_escrito);
    return 0;
}

static esp_err_t enviar_bytes(const char *json)
{
    size_t n = strlen(json);
    uint8_t *trama = malloc(n + 4);
    if (!trama) return ESP_ERR_NO_MEM;
    trama[0] = n >> 24; trama[1] = n >> 16; trama[2] = n >> 8; trama[3] = n;
    memcpy(trama + 4, json, n);
    esp_err_t r = ESP_OK;
    xSemaphoreTake(g_tx, portMAX_DELAY);
    uint16_t conn = S.conn;
    int trozo = ble_att_mtu(conn) - 3;
    if (trozo > 500) trozo = 500;
    if (trozo < 20) trozo = 20;
    for (size_t i = 0; i < n + 4 && r == ESP_OK; i += trozo) {
        size_t t = (n + 4 - i) < (size_t)trozo ? (n + 4 - i) : (size_t)trozo;
        xSemaphoreTake(g_escrito, 0);
        if (ble_gattc_write_flat(conn, g_rx_handle, trama + i, t, al_escribir, NULL) != 0) { r = ESP_FAIL; break; }
        if (xSemaphoreTake(g_escrito, pdMS_TO_TICKS(10000)) != pdTRUE || g_escrito_estado != 0) r = ESP_FAIL;
    }
    xSemaphoreGive(g_tx);
    free(trama);
    return r;
}

static esp_err_t enviar_plano(cJSON *obj)
{
    char *j = cJSON_PrintUnformatted(obj);
    if (!j) return ESP_ERR_NO_MEM;
    esp_err_t r = enviar_bytes(j);
    free(j);
    return r;
}

static esp_err_t enviar_cifrado(cJSON *obj)
{
    char *j = cJSON_PrintUnformatted(obj);
    if (!j) return ESP_ERR_NO_MEM;
    size_t n = strlen(j);
    uint8_t *caja = malloc(12 + n + 16);
    if (!caja) { free(j); return ESP_ERR_NO_MEM; }
    esp_fill_random(caja, 12);
    mbedtls_gcm_context g;
    mbedtls_gcm_init(&g);
    mbedtls_gcm_setkey(&g, MBEDTLS_CIPHER_ID_AES, S.clave, 256);
    int e = mbedtls_gcm_crypt_and_tag(&g, MBEDTLS_GCM_ENCRYPT, n, caja, 12, NULL, 0,
                                      (const uint8_t *)j, caja + 12, 16, caja + 12 + n);
    mbedtls_gcm_free(&g);
    free(j);
    if (e) { free(caja); return ESP_FAIL; }
    char *t = b64(caja, 12 + n + 16);
    free(caja);
    if (!t) return ESP_ERR_NO_MEM;
    cJSON *env = cJSON_CreateObject();
    cJSON_AddStringToObject(env, "e", t);
    free(t);
    esp_err_t r = enviar_plano(env);
    cJSON_Delete(env);
    return r;
}

static cJSON *descifrar(cJSON *obj)
{
    cJSON *e = cJSON_GetObjectItem(obj, "e");
    if (!cJSON_IsString(e)) return NULL;
    size_t n = 0;
    uint8_t *caja = de_b64(e->valuestring, &n);
    if (!caja || n < 12 + 16) { free(caja); return NULL; }
    size_t largo = n - 12 - 16;
    char *plano = malloc(largo + 1);
    if (!plano) { free(caja); return NULL; }
    mbedtls_gcm_context g;
    mbedtls_gcm_init(&g);
    mbedtls_gcm_setkey(&g, MBEDTLS_CIPHER_ID_AES, S.clave, 256);
    int r = mbedtls_gcm_auth_decrypt(&g, largo, caja, 12, NULL, 0, caja + 12 + largo, 16,
                                     caja + 12, (uint8_t *)plano);
    mbedtls_gcm_free(&g);
    free(caja);
    if (r) { free(plano); return NULL; }
    plano[largo] = 0;
    cJSON *m = cJSON_Parse(plano);
    free(plano);
    return m;
}

static void derivar(const uint8_t secreto[32], const char *info, const uint8_t *pub_tel,
                    const uint8_t *pub_pc, uint8_t *out, size_t largo)
{
    uint8_t i[16 + 64];
    size_t ni = strlen(info);
    memcpy(i, info, ni);
    memcpy(i + ni, pub_tel, 32);
    memcpy(i + ni + 32, pub_pc, 32);
    mbedtls_hkdf(mbedtls_md_info_from_type(MBEDTLS_MD_SHA256), SAL, SAL_LARGO, secreto, 32,
                 i, ni + 64, out, largo);
}

/* El teléfono saluda: intercambio de llaves y código de 4 números */
static void saludo(cJSON *obj)
{
    cJSON *pub = cJSON_GetObjectItem(obj, "pub");
    if (!cJSON_IsString(pub)) return;
    size_t n = 0;
    uint8_t *pub_tel = de_b64(pub->valuestring, &n);
    if (!pub_tel || n != 32) { free(pub_tel); return; }

    uint8_t pub_pc[32], secreto[32];
    size_t olen = 0;
    mbedtls_ecp_point q_tel;
    mbedtls_mpi z;
    mbedtls_ecp_point_init(&q_tel);
    mbedtls_mpi_init(&z);
    int e = mbedtls_ecp_point_write_binary(&S.grupo, &S.publica, MBEDTLS_ECP_PF_UNCOMPRESSED, &olen, pub_pc, 32);
    if (!e) e = mbedtls_ecp_point_read_binary(&S.grupo, &q_tel, pub_tel, 32);
    if (!e) e = mbedtls_ecdh_compute_shared(&S.grupo, &z, &q_tel, &S.privada, azar, NULL);
    if (!e) e = mbedtls_mpi_write_binary_le(&z, secreto, 32);
    mbedtls_ecp_point_free(&q_tel);
    mbedtls_mpi_free(&z);
    if (e) { ESP_LOGE(TAG, "Intercambio de llaves falló (%d)", e); free(pub_tel); return; }

    uint8_t cod[4];
    xSemaphoreTake(g_mutex, portMAX_DELAY);
    derivar(secreto, "clave", pub_tel, pub_pc, S.clave, 32);
    derivar(secreto, "codigo", pub_tel, pub_pc, cod, 4);
    uint32_t c = ((uint32_t)cod[0] << 24 | cod[1] << 16 | cod[2] << 8 | cod[3]) % 10000;
    snprintf(S.codigo, sizeof(S.codigo), "%04lu", (unsigned long)c);
    cJSON *nom = cJSON_GetObjectItem(obj, "nombre");
    const char *nombre = cJSON_IsString(nom) ? nom->valuestring : "";
    size_t ln = strnlen(nombre, sizeof(S.paciente) - 1);
    while (ln > 0 && (((uint8_t)nombre[ln]) & 0xC0) == 0x80) ln--;   // no cortar una letra
    memcpy(S.paciente, nombre, ln);
    S.paciente[ln] = 0;
    xSemaphoreGive(g_mutex);
    memset(secreto, 0, sizeof(secreto));
    free(pub_tel);

    cJSON *r = cJSON_CreateObject();
    char *t = b64(pub_pc, 32);
    cJSON_AddStringToObject(r, "tipo", "hola");
    cJSON_AddStringToObject(r, "pub", t ? t : "");
    cJSON_AddStringToObject(r, "equipo", "Lector HypokratIA");
    cJSON_AddStringToObject(r, "version", VERSION);
    free(t);
    enviar_plano(r);
    cJSON_Delete(r);

    xSemaphoreTake(g_mutex, portMAX_DELAY);
    S.con_clave = true;
    S.estado = E_SOLICITUD;
    s_estado_desde = esp_timer_get_time();
    xSemaphoreGive(g_mutex);
    ESP_LOGI(TAG, "Solicitud de un paciente · código %s", S.codigo);
    abrir_pagina();
}

static void recibir(const char *raw)
{
    cJSON *obj = cJSON_Parse(raw);
    if (!obj) return;
    if (!S.con_clave) {
        cJSON *tipo = cJSON_GetObjectItem(obj, "tipo");
        if (cJSON_IsString(tipo) && strcmp(tipo->valuestring, "hola") == 0 && S.estado == E_HANDSHAKE) saludo(obj);
        cJSON_Delete(obj);
        return;
    }
    cJSON *m = descifrar(obj);
    cJSON_Delete(obj);
    if (!m) { ESP_LOGW(TAG, "Mensaje que no se pudo descifrar"); return; }
    cJSON *tipo = cJSON_GetObjectItem(m, "tipo");
    const char *t = cJSON_IsString(tipo) ? tipo->valuestring : "";
    xSemaphoreTake(g_mutex, portMAX_DELAY);
    if (strcmp(t, "ficha") == 0 && S.estado == E_ACEPTADA) {
        cJSON *f = cJSON_GetObjectItem(m, "ficha");
        free(S.ficha);
        S.ficha = cJSON_IsObject(f) ? cJSON_PrintUnformatted(f) : strdup("{}");
        S.estado = E_ACTIVA;
        s_estado_desde = esp_timer_get_time();
        ESP_LOGI(TAG, "Ficha recibida (%u bytes)", S.ficha ? (unsigned)strlen(S.ficha) : 0);
    } else if (strcmp(t, "ok") == 0) {
        cJSON *n = cJSON_GetObjectItem(m, "n");
        if (cJSON_IsNumber(n) && n->valueint == S.esperando && S.esperando) {
            S.respuesta = m;
            m = NULL;
            xSemaphoreGive(g_resp);
        }
    } else if (strcmp(t, "permiso") == 0) {
        cJSON *p = cJSON_GetObjectItem(m, "permiso"), *ahora = cJSON_GetObjectItem(m, "ahora");
        free(S.permiso);
        S.permiso = cJSON_IsString(p) ? strdup(p->valuestring) : NULL;
        bool renovar = !S.pidio_certificado && s_llave_pem && cJSON_IsNumber(ahora)
                       && (!s_cert || s_cert_vence - (int64_t)ahora->valuedouble < 30 * 86400);
        if (renovar) S.pidio_certificado = true;
        xSemaphoreGive(g_mutex);
        ESP_LOGI(TAG, "Permiso de consulta recibido");
        if (renovar) {
            char *csr = crear_csr();
            if (csr) {
                cJSON *q = cJSON_CreateObject();
                cJSON_AddStringToObject(q, "tipo", "certificado_pedir");
                cJSON_AddStringToObject(q, "nombre", s_nombre);
                cJSON_AddStringToObject(q, "csr", csr);
                enviar_cifrado(q);
                cJSON_Delete(q);
                free(csr);
                ESP_LOGI(TAG, "Certificado pedido al teléfono");
            }
        }
        cJSON_Delete(m);
        return;
    } else if (strcmp(t, "certificado") == 0) {
        cJSON *c = cJSON_GetObjectItem(m, "certificado");
        xSemaphoreGive(g_mutex);
        int64_t vence = 0;
        esp_err_t g = ESP_FAIL;
        if (!cJSON_IsString(c)) {
            cJSON *e = cJSON_GetObjectItem(m, "error");
            s_cert_estado = cJSON_IsString(e) ? "el servidor no lo emitió" : "no llegó el certificado";
        } else if (!cert_valido(c->valuestring, &vence)) {
            s_cert_estado = "certificado recibido no corresponde a la llave";
        } else if ((g = nvs_guardar_blob("certpem", c->valuestring)) != ESP_OK) {
            s_cert_estado = "no se pudo guardar el certificado";
            ESP_LOGW(TAG, "NVS: %s", esp_err_to_name(g));
        } else {
            s_cert_nuevo = true;                         // se activa al terminar la consulta
            s_cert_estado = "guardado: se activa al terminar la consulta";
            ESP_LOGI(TAG, "Certificado nuevo guardado (%u bytes)", (unsigned)strlen(c->valuestring));
        }
        cJSON_Delete(m);
        return;
    } else if (strcmp(t, "fin") == 0) {
        xSemaphoreGive(g_mutex);
        ESP_LOGI(TAG, "El paciente terminó la consulta");
        terminar_sesion(true);
        cJSON_Delete(m);
        return;
    }
    xSemaphoreGive(g_mutex);
    cJSON_Delete(m);
}

/* Envía y espera la confirmación del teléfono (notas, accesos, idioma) */
static cJSON *pedir(cJSON *obj, int segundos)
{
    xSemaphoreTake(g_mutex, portMAX_DELAY);
    if (S.estado == E_NINGUNA) { xSemaphoreGive(g_mutex); return NULL; }
    int n = ++S.sec;
    S.esperando = n;
    cJSON_Delete(S.respuesta);
    S.respuesta = NULL;
    xSemaphoreTake(g_resp, 0);
    xSemaphoreGive(g_mutex);
    cJSON_AddNumberToObject(obj, "n", n);
    cJSON *r = NULL;
    if (enviar_cifrado(obj) == ESP_OK && xSemaphoreTake(g_resp, pdMS_TO_TICKS(segundos * 1000)) == pdTRUE) {
        xSemaphoreTake(g_mutex, portMAX_DELAY);
        r = S.respuesta;
        S.respuesta = NULL;
        xSemaphoreGive(g_mutex);
    }
    xSemaphoreTake(g_mutex, portMAX_DELAY);
    S.esperando = 0;
    xSemaphoreGive(g_mutex);
    return r;
}

static void nueva_sesion(uint16_t conn)
{
    xSemaphoreTake(g_mutex, portMAX_DELAY);
    S.estado = E_HANDSHAKE;
    s_estado_desde = esp_timer_get_time();
    S.conn = conn;
    S.con_clave = false;
    S.nota_guardada = false;
    S.codigo[0] = S.paciente[0] = 0;
    S.sec = S.esperando = 0;
    mbedtls_ecp_group_init(&S.grupo);
    mbedtls_mpi_init(&S.privada);
    mbedtls_ecp_point_init(&S.publica);
    mbedtls_ecp_group_load(&S.grupo, MBEDTLS_ECP_DP_CURVE25519);
    mbedtls_ecp_gen_keypair(&S.grupo, &S.privada, &S.publica, azar, NULL);
    xSemaphoreGive(g_mutex);
}

static void terminar_sesion(bool desconectar)
{
    xSemaphoreTake(g_mutex, portMAX_DELAY);
    if (S.estado == E_NINGUNA) { xSemaphoreGive(g_mutex); return; }
    uint16_t conn = S.conn;
    if (S.ficha) {                                            // la ficha sale de la memoria
        memset(S.ficha, 0, strlen(S.ficha));
        free(S.ficha);
        S.ficha = NULL;
    }
    memset(S.clave, 0, sizeof(S.clave));
    mbedtls_ecp_group_free(&S.grupo);
    mbedtls_mpi_free(&S.privada);
    mbedtls_ecp_point_free(&S.publica);
    free(S.permiso);
    S.permiso = NULL;
    S.pidio_certificado = false;
    S.estado = E_NINGUNA;
    S.con_clave = false;
    if (S.esperando) xSemaphoreGive(g_resp);                  // libera a quien espera
    xSemaphoreGive(g_mutex);
    if (desconectar) ble_gap_terminate(conn, BLE_ERR_REM_USER_CONN_TERM);
    ESP_LOGI(TAG, "Consulta terminada; ficha borrada");
    if (s_cert_nuevo) {                                       // estrenar el certificado (https)
        ESP_LOGI(TAG, "Reiniciando para usar el certificado nuevo");
        vTaskDelay(pdMS_TO_TICKS(1500));
        esp_restart();
    }
}

/* Vigilante: ninguna conexión queda colgada. Si el teléfono se fue (salió de
 * la app, perdió el Bluetooth) o la página del médico se cerró, el lector
 * corta solo y vuelve a esperar pacientes. */
static void tarea_vigilante(void *arg)
{
    for (;;) {
        vTaskDelay(pdMS_TO_TICKS(5000));
        int64_t ahora = esp_timer_get_time();
        int estado = S.estado;
        int64_t en_estado = (ahora - s_estado_desde) / 1000000;
        int64_t sin_pagina = (ahora - s_ultimo_sondeo) / 1000000;
        const char *motivo = NULL;
        if (estado == E_HANDSHAKE && en_estado > 30) motivo = "el teléfono no completó la conexión";
        else if (estado == E_SOLICITUD && en_estado > 200) motivo = "nadie aceptó la solicitud";
        else if (estado == E_ACEPTADA && en_estado > 120) motivo = "el teléfono no envió la ficha";
        else if (estado == E_ACTIVA && sin_pagina > 600) motivo = "la página del médico está cerrada";
        else if (estado == E_ACTIVA && en_estado > 3 * 3600) motivo = "pasaron 3 horas";
        if (motivo) {
            ESP_LOGW(TAG, "Se corta la conexión: %s", motivo);
            if (S.con_clave) {
                cJSON *m = cJSON_CreateObject();
                cJSON_AddStringToObject(m, "tipo", "fin");
                enviar_cifrado(m);
                cJSON_Delete(m);
            }
            terminar_sesion(true);
        }
    }
}

/* ── Bluetooth: el TELÉFONO se anuncia ("HypokratIA") y el lector lo busca ── */

static const ble_uuid128_t SERVICIO = BLE_UUID128_INIT(0x01, 0xb0, 0x46, 0x50, 0x49, 0x48, 0x0e, 0x9d,
                                                       0x39, 0x4c, 0x1f, 0x6b, 0x01, 0x00, 0x8a, 0x6e);
static const ble_uuid128_t CARACT_RX = BLE_UUID128_INIT(0x01, 0xb0, 0x46, 0x50, 0x49, 0x48, 0x0e, 0x9d,
                                                        0x39, 0x4c, 0x1f, 0x6b, 0x02, 0x00, 0x8a, 0x6e);
static const ble_uuid128_t CARACT_TX = BLE_UUID128_INIT(0x01, 0xb0, 0x46, 0x50, 0x49, 0x48, 0x0e, 0x9d,
                                                        0x39, 0x4c, 0x1f, 0x6b, 0x03, 0x00, 0x8a, 0x6e);

static uint8_t s_tipo_dir;
static uint16_t s_fin_servicio;
static ble_addr_t s_ultimo;              // teléfono recién atendido: no reconectar por 15 s
static int64_t s_ultimo_hasta = 0;

/* Lo que llega del teléfono se junta aquí y lo procesa tarea_procesar */
static SemaphoreHandle_t g_rx_mutex;
static uint8_t *g_rx = NULL;
static size_t g_rx_largo = 0, g_rx_cap = 0;
static TaskHandle_t g_procesador;

static void buscar(void);
static int evento_gap(struct ble_gap_event *ev, void *arg);

static void tarea_procesar(void *arg)
{
    for (;;) {
        ulTaskNotifyTake(pdTRUE, portMAX_DELAY);
        for (;;) {
            char *msg = NULL;
            xSemaphoreTake(g_rx_mutex, portMAX_DELAY);
            if (g_rx_largo >= 4) {
                uint32_t n = (uint32_t)g_rx[0] << 24 | g_rx[1] << 16 | g_rx[2] << 8 | g_rx[3];
                if (n > 8 * 1024 * 1024) {
                    g_rx_largo = 0;
                } else if (g_rx_largo >= 4 + n) {
                    msg = malloc(n + 1);
                    if (msg) { memcpy(msg, g_rx + 4, n); msg[n] = 0; }
                    memmove(g_rx, g_rx + 4 + n, g_rx_largo - 4 - n);
                    g_rx_largo -= 4 + n;
                }
            }
            xSemaphoreGive(g_rx_mutex);
            if (!msg) break;
            recibir(msg);
            free(msg);
        }
    }
}

static void agregar_rx(const struct os_mbuf *om)
{
    uint16_t n = OS_MBUF_PKTLEN(om);
    xSemaphoreTake(g_rx_mutex, portMAX_DELAY);
    if (g_rx_largo + n > g_rx_cap) {
        size_t cap = g_rx_cap ? g_rx_cap * 2 : 4096;
        while (cap < g_rx_largo + n) cap *= 2;
        uint8_t *nuevo = realloc(g_rx, cap);
        if (!nuevo) { xSemaphoreGive(g_rx_mutex); return; }
        g_rx = nuevo;
        g_rx_cap = cap;
    }
    uint16_t copiado = 0;
    ble_hs_mbuf_to_flat(om, g_rx + g_rx_largo, n, &copiado);
    g_rx_largo += copiado;
    xSemaphoreGive(g_rx_mutex);
    xTaskNotifyGive(g_procesador);
}

static int al_suscribir(uint16_t conn, const struct ble_gatt_error *err, struct ble_gatt_attr *attr, void *arg)
{
    if (err->status != 0) { ble_gap_terminate(conn, BLE_ERR_REM_USER_CONN_TERM); return 0; }
    ESP_LOGI(TAG, "Teléfono conectado por Bluetooth; esperando su saludo");
    return 0;
}

static int al_descriptor(uint16_t conn, const struct ble_gatt_error *err, uint16_t chr_val,
                         const struct ble_gatt_dsc *dsc, void *arg)
{
    static uint16_t cccd = 0;
    if (err->status == 0 && dsc && ble_uuid_cmp(&dsc->uuid.u, BLE_UUID16_DECLARE(BLE_GATT_DSC_CLT_CFG_UUID16)) == 0) {
        cccd = dsc->handle;
    } else if (err->status == BLE_HS_EDONE) {
        if (!cccd) { ble_gap_terminate(conn, BLE_ERR_REM_USER_CONN_TERM); return 0; }
        static const uint8_t activar[2] = { 0x01, 0x00 };   // notificaciones
        ble_gattc_write_flat(conn, cccd, activar, 2, al_suscribir, NULL);
        cccd = 0;
    } else if (err->status != 0) {
        ble_gap_terminate(conn, BLE_ERR_REM_USER_CONN_TERM);
    }
    return 0;
}

static int al_caracteristica(uint16_t conn, const struct ble_gatt_error *err, const struct ble_gatt_chr *chr, void *arg)
{
    if (err->status == 0 && chr) {
        if (ble_uuid_cmp(&chr->uuid.u, &CARACT_RX.u) == 0) g_rx_handle = chr->val_handle;
        if (ble_uuid_cmp(&chr->uuid.u, &CARACT_TX.u) == 0) g_tx_handle = chr->val_handle;
    } else if (err->status == BLE_HS_EDONE) {
        if (!g_rx_handle || !g_tx_handle) { ble_gap_terminate(conn, BLE_ERR_REM_USER_CONN_TERM); return 0; }
        ble_gattc_disc_all_dscs(conn, g_tx_handle, s_fin_servicio, al_descriptor, NULL);
    } else if (err->status != 0) {
        ble_gap_terminate(conn, BLE_ERR_REM_USER_CONN_TERM);
    }
    return 0;
}

static int al_servicio(uint16_t conn, const struct ble_gatt_error *err, const struct ble_gatt_svc *svc, void *arg)
{
    static uint16_t inicio = 0;
    if (err->status == 0 && svc) {
        inicio = svc->start_handle;
        s_fin_servicio = svc->end_handle;
    } else if (err->status == BLE_HS_EDONE && inicio) {
        g_rx_handle = g_tx_handle = 0;
        ble_gattc_disc_all_chrs(conn, inicio, s_fin_servicio, al_caracteristica, NULL);
        inicio = 0;
    } else {
        ble_gap_terminate(conn, BLE_ERR_REM_USER_CONN_TERM);
    }
    return 0;
}

static int al_mtu(uint16_t conn, const struct ble_gatt_error *err, uint16_t mtu, void *arg)
{
    ble_gattc_disc_svc_by_uuid(conn, &SERVICIO.u, al_servicio, NULL);
    return 0;
}

static bool anuncia_hipokratia(const struct ble_gap_disc_desc *d)
{
    struct ble_hs_adv_fields f;
    if (ble_hs_adv_parse_fields(&f, d->data, d->length_data) != 0) return false;
    for (int i = 0; i < f.num_uuids128; i++) {
        if (ble_uuid_cmp(&f.uuids128[i].u, &SERVICIO.u) == 0) return true;
    }
    return false;
}

static int evento_gap(struct ble_gap_event *ev, void *arg)
{
    switch (ev->type) {
    case BLE_GAP_EVENT_DISC:
        if (S.estado != E_NINGUNA || !anuncia_hipokratia(&ev->disc)) return 0;
        if (esp_timer_get_time() < s_ultimo_hasta && ble_addr_cmp(&ev->disc.addr, &s_ultimo) == 0) return 0;
        ble_gap_disc_cancel();
        s_ultimo = ev->disc.addr;
        if (ble_gap_connect(s_tipo_dir, &ev->disc.addr, 15000, NULL, evento_gap, NULL) != 0) buscar();
        return 0;
    case BLE_GAP_EVENT_DISC_COMPLETE:
        if (S.estado == E_NINGUNA) buscar();
        return 0;
    case BLE_GAP_EVENT_CONNECT:
        if (ev->connect.status != 0) { buscar(); return 0; }
        nueva_sesion(ev->connect.conn_handle);
        ble_gattc_exchange_mtu(ev->connect.conn_handle, al_mtu, NULL);
        return 0;
    case BLE_GAP_EVENT_DISCONNECT:
        ESP_LOGI(TAG, "Bluetooth desconectado");
        terminar_sesion(false);
        s_ultimo_hasta = esp_timer_get_time() + 15000000;
        xSemaphoreTake(g_rx_mutex, portMAX_DELAY);
        g_rx_largo = 0;
        xSemaphoreGive(g_rx_mutex);
        buscar();
        return 0;
    case BLE_GAP_EVENT_NOTIFY_RX:
        if (ev->notify_rx.attr_handle == g_tx_handle) agregar_rx(ev->notify_rx.om);
        return 0;
    default:
        return 0;
    }
}

static void buscar(void)
{
    struct ble_gap_disc_params p = { .passive = 0, .filter_duplicates = 0, .itvl = 0x50, .window = 0x30 };
    int r = ble_gap_disc(s_tipo_dir, BLE_HS_FOREVER, &p, evento_gap, NULL);
    if (r != 0 && r != BLE_HS_EALREADY) ESP_LOGW(TAG, "No se pudo buscar por Bluetooth (%d)", r);
}

static void al_sincronizar(void)
{
    ble_hs_id_infer_auto(0, &s_tipo_dir);
    ESP_LOGI(TAG, "Bluetooth listo: buscando teléfonos con HypokratIA cerca");
    buscar();
}

static void tarea_bluetooth(void *arg)
{
    nimble_port_run();
    nimble_port_freertos_deinit();
}

/* ── Página para el médico (solo por la red USB) ─────────────────────── */

extern const char PAGINA_INICIO[] asm("_binary_atencion_html_start");
extern const char PAGINA_FIN[] asm("_binary_atencion_html_end");

static bool permitido(httpd_req_t *req)
{
    char v[96], origen[96];
    if (httpd_req_get_hdr_value_str(req, "Host", v, sizeof(v)) != ESP_OK) return false;
    bool por_nombre = s_cert && strcasecmp(v, s_dominio) == 0;
    if (!por_nombre && strcmp(v, DIRECCION) != 0) return false;
    if (req->method != HTTP_GET) {
        if (por_nombre) snprintf(origen, sizeof(origen), "https://%s", s_dominio);
        else snprintf(origen, sizeof(origen), "http://" DIRECCION);
        if (httpd_req_get_hdr_value_str(req, "Origin", v, sizeof(v)) != ESP_OK || strcasecmp(v, origen) != 0)
            return false;
    }
    return true;
}

static esp_err_t responder(httpd_req_t *req, const char *estado, const char *json)
{
    httpd_resp_set_status(req, estado);
    httpd_resp_set_type(req, "application/json; charset=utf-8");
    httpd_resp_set_hdr(req, "Cache-Control", "no-store");
    return httpd_resp_send(req, json, HTTPD_RESP_USE_STRLEN);
}

static esp_err_t error(httpd_req_t *req, const char *estado, const char *texto)
{
    cJSON *o = cJSON_CreateObject();
    cJSON_AddStringToObject(o, "detail", texto);
    char *j = cJSON_PrintUnformatted(o);
    esp_err_t r = responder(req, estado, j ? j : "{}");
    free(j);
    cJSON_Delete(o);
    return r;
}

#define PROHIBIDO(req) do { if (!permitido(req)) { httpd_resp_set_status(req, "403 Forbidden"); \
                            return httpd_resp_send(req, "", 0); } } while (0)
#define CON_CONSULTA(req) do { if (S.estado == E_NINGUNA) \
                            return error(req, "409 Conflict", "No hay una consulta en curso"); } while (0)

static cJSON *leer_json(httpd_req_t *req)
{
    if (req->content_len > 256 * 1024) return NULL;
    char *b = malloc(req->content_len + 1);
    if (!b) return NULL;
    size_t leido = 0;
    while (leido < req->content_len) {
        int r = httpd_req_recv(req, b + leido, req->content_len - leido);
        if (r <= 0) { free(b); return NULL; }
        leido += r;
    }
    b[leido] = 0;
    cJSON *o = cJSON_Parse(b);
    free(b);
    return o;
}

/* RUT chileno válido, o profesional extranjero: EXT-<país>-<registro> */
static bool rut_valido(const char *rut)
{
    char u[48];
    size_t n = 0;
    for (const char *c = rut; *c && n < sizeof(u) - 1; c++) u[n++] = toupper((unsigned char)*c);
    u[n] = 0;
    while (n && u[n - 1] == ' ') u[--n] = 0;
    char *p = u;
    while (*p == ' ') p++;
    if (strncmp(p, "EXT-", 4) == 0 && isupper((unsigned char)p[4]) && isupper((unsigned char)p[5]) && p[6] == '-') {
        size_t largo = strlen(p + 7);
        if (largo < 3 || largo > 30) return false;
        for (const char *c = p + 7; *c; c++)
            if (!(isupper((unsigned char)*c) || isdigit((unsigned char)*c) || strchr("./-", *c))) return false;
        return true;
    }
    char limpio[16];
    size_t m = 0;
    for (const char *c = p; *c; c++) {
        if (*c == '.' || *c == ' ') continue;
        if (m >= sizeof(limpio) - 1) return false;
        limpio[m++] = *c;
    }
    limpio[m] = 0;
    if (m >= 2 && limpio[m - 2] == '-') { limpio[m - 2] = limpio[m - 1]; limpio[--m] = 0; }
    if (m < 7 || m > 9) return false;
    char dv = limpio[m - 1];
    int suma = 0, mult = 2;
    for (int i = m - 2; i >= 0; i--) {
        if (!isdigit((unsigned char)limpio[i])) return false;
        suma += (limpio[i] - '0') * mult;
        mult = mult == 7 ? 2 : mult + 1;
    }
    int r = 11 - suma % 11;
    char esperado = r == 11 ? '0' : r == 10 ? 'K' : '0' + r;
    return dv == esperado;
}

static bool profesional(cJSON *b, const char **nombre, const char **rut)
{
    cJSON *n = cJSON_GetObjectItem(b, "nombre"), *r = cJSON_GetObjectItem(b, "rut");
    *nombre = cJSON_IsString(n) ? n->valuestring : "";
    *rut = cJSON_IsString(r) ? r->valuestring : "";
    size_t ln = strlen(*nombre);
    while (ln && **nombre == ' ') { (*nombre)++; ln--; }
    return ln >= 3 && rut_valido(*rut);
}

static esp_err_t w_pagina(httpd_req_t *req)
{
    PROHIBIDO(req);
    httpd_resp_set_type(req, "text/html; charset=utf-8");
    httpd_resp_set_hdr(req, "Cache-Control", "no-store");
    httpd_resp_set_hdr(req, "X-Frame-Options", "DENY");
    return httpd_resp_send(req, PAGINA_INICIO, PAGINA_FIN - PAGINA_INICIO - 1);
}

static esp_err_t w_estado(httpd_req_t *req)
{
    PROHIBIDO(req);
    s_ultimo_sondeo = esp_timer_get_time();
    cJSON *o = cJSON_CreateObject();
    xSemaphoreTake(g_mutex, portMAX_DELAY);
    cJSON_AddStringToObject(o, "estado", NOMBRE_ESTADO[S.estado]);
    cJSON_AddBoolToObject(o, "https", s_cert != NULL);
    cJSON_AddStringToObject(o, "certificado", s_cert_estado);
    if (S.permiso && S.estado >= E_ACEPTADA) cJSON_AddStringToObject(o, "permiso", S.permiso);
    if (S.estado >= E_SOLICITUD) {
        cJSON_AddStringToObject(o, "paciente", S.paciente);
        cJSON_AddStringToObject(o, "codigo", S.codigo);
    }
    xSemaphoreGive(g_mutex);
    char *j = cJSON_PrintUnformatted(o);
    cJSON_Delete(o);
    esp_err_t r = responder(req, "200 OK", j ? j : "{}");
    free(j);
    return r;
}

static esp_err_t w_aceptar(httpd_req_t *req)
{
    PROHIBIDO(req);
    CON_CONSULTA(req);
    if (S.estado == E_SOLICITUD) {
        S.estado = E_ACEPTADA;
        s_estado_desde = esp_timer_get_time();
        cJSON *m = cJSON_CreateObject();
        cJSON_AddStringToObject(m, "tipo", "aceptado");
        enviar_cifrado(m);
        cJSON_Delete(m);
        ESP_LOGI(TAG, "El médico aceptó");
    }
    return responder(req, "200 OK", "{\"ok\":true}");
}

static esp_err_t w_rechazar(httpd_req_t *req)
{
    PROHIBIDO(req);
    CON_CONSULTA(req);
    cJSON *m = cJSON_CreateObject();
    cJSON_AddStringToObject(m, "tipo", "rechazado");
    enviar_cifrado(m);
    cJSON_Delete(m);
    terminar_sesion(true);
    return responder(req, "200 OK", "{\"ok\":true}");
}

static esp_err_t w_terminar(httpd_req_t *req)
{
    PROHIBIDO(req);
    if (S.estado != E_NINGUNA) {
        if (S.con_clave) {
            cJSON *m = cJSON_CreateObject();
            cJSON_AddStringToObject(m, "tipo", "fin");
            enviar_cifrado(m);
            cJSON_Delete(m);
        }
        terminar_sesion(true);
    }
    return responder(req, "200 OK", "{\"ok\":true}");
}

static esp_err_t enviar_ficha(httpd_req_t *req, const char *ficha)
{
    httpd_resp_set_type(req, "application/json; charset=utf-8");
    httpd_resp_set_hdr(req, "Cache-Control", "no-store");
    httpd_resp_send_chunk(req, "{\"ficha\":", HTTPD_RESP_USE_STRLEN);
    size_t n = strlen(ficha);
    for (size_t i = 0; i < n; i += 4096) {
        if (httpd_resp_send_chunk(req, ficha + i, (n - i) < 4096 ? (n - i) : 4096) != ESP_OK) return ESP_FAIL;
    }
    httpd_resp_send_chunk(req, "}", 1);
    return httpd_resp_send_chunk(req, NULL, 0);
}

static esp_err_t w_identificar(httpd_req_t *req)
{
    PROHIBIDO(req);
    CON_CONSULTA(req);
    if (!S.ficha) return error(req, "409 Conflict", "Esperando la ficha del teléfono, intente en unos segundos");
    cJSON *b = leer_json(req);
    const char *nombre, *rut;
    if (!b || !profesional(b, &nombre, &rut)) {
        cJSON_Delete(b);
        return error(req, "400 Bad Request", "Ingresa tu nombre completo y un RUT válido");
    }
    cJSON *m = cJSON_CreateObject();
    cJSON_AddStringToObject(m, "tipo", "acceso");
    cJSON_AddStringToObject(m, "nombre", nombre);
    cJSON_AddStringToObject(m, "rut", rut);
    cJSON_Delete(b);
    cJSON *r = pedir(m, 25);
    cJSON_Delete(m);
    if (!r) return error(req, "504 Gateway Timeout", "El teléfono del paciente no respondió");
    cJSON_Delete(r);
    xSemaphoreTake(g_mutex, portMAX_DELAY);
    char *copia = S.ficha ? strdup(S.ficha) : NULL;
    xSemaphoreGive(g_mutex);
    if (!copia) return error(req, "409 Conflict", "La consulta terminó");
    esp_err_t e = enviar_ficha(req, copia);
    memset(copia, 0, strlen(copia));
    free(copia);
    return e;
}

static esp_err_t w_nota(httpd_req_t *req)
{
    PROHIBIDO(req);
    CON_CONSULTA(req);
    if (S.nota_guardada) return error(req, "409 Conflict", "La atención de esta consulta ya fue guardada");
    cJSON *b = leer_json(req);
    const char *nombre, *rut;
    if (!b || !profesional(b, &nombre, &rut)) {
        cJSON_Delete(b);
        return error(req, "400 Bad Request", "Falta tu nombre o RUT");
    }
    cJSON *m = cJSON_CreateObject();
    cJSON_AddStringToObject(m, "tipo", "nota");
    cJSON_AddStringToObject(m, "nombre", nombre);
    cJSON_AddStringToObject(m, "rut", rut);
    cJSON *contenido = cJSON_AddObjectToObject(m, "contenido");
    cJSON *c = cJSON_GetObjectItem(b, "contenido"), *it;
    if (cJSON_IsObject(c)) {
        cJSON_ArrayForEach(it, c) {
            if (cJSON_IsString(it)) {
                cJSON_AddStringToObject(contenido, it->string, it->valuestring);
            } else {
                char *t = cJSON_PrintUnformatted(it);
                cJSON_AddStringToObject(contenido, it->string, t ? t : "");
                free(t);
            }
        }
    }
    cJSON_Delete(b);
    cJSON *r = pedir(m, 25);
    cJSON_Delete(m);
    if (!r) return error(req, "504 Gateway Timeout", "El teléfono del paciente no respondió; la nota NO se guardó");
    cJSON *ok = cJSON_GetObjectItem(r, "ok");
    if (cJSON_IsFalse(ok)) {
        cJSON *d = cJSON_GetObjectItem(r, "detail");
        esp_err_t e = error(req, "400 Bad Request", cJSON_IsString(d) ? d->valuestring : "El teléfono no pudo guardar la nota");
        cJSON_Delete(r);
        return e;
    }
    cJSON_Delete(r);
    S.nota_guardada = true;
    return responder(req, "200 OK", "{\"ok\":true}");
}

static esp_err_t w_idioma(httpd_req_t *req)
{
    PROHIBIDO(req);
    CON_CONSULTA(req);
    cJSON *b = leer_json(req);
    cJSON *i = b ? cJSON_GetObjectItem(b, "idioma") : NULL;
    const char *idioma = cJSON_IsString(i) ? i->valuestring : "";
    if (strcmp(idioma, "en") && strcmp(idioma, "de") && strcmp(idioma, "fr")) {
        cJSON_Delete(b);
        return error(req, "400 Bad Request", "Idioma no disponible");
    }
    cJSON *m = cJSON_CreateObject();
    cJSON_AddStringToObject(m, "tipo", "idioma");
    cJSON_AddStringToObject(m, "idioma", idioma);
    cJSON_Delete(b);
    cJSON *r = pedir(m, 240);
    cJSON_Delete(m);
    if (!r) return error(req, "504 Gateway Timeout", "El teléfono no respondió a tiempo");
    cJSON *f = cJSON_GetObjectItem(r, "ficha"), *ok = cJSON_GetObjectItem(r, "ok");
    if (cJSON_IsFalse(ok) || !cJSON_IsObject(f)) {
        cJSON *d = cJSON_GetObjectItem(r, "detail");
        esp_err_t e = error(req, "400 Bad Request", cJSON_IsString(d) ? d->valuestring : "El teléfono no pudo traducir");
        cJSON_Delete(r);
        return e;
    }
    char *j = cJSON_PrintUnformatted(f);
    cJSON_Delete(r);
    if (!j) return error(req, "500 Internal Server Error", "Sin memoria");
    esp_err_t e = enviar_ficha(req, j);
    free(j);
    return e;
}

/* ── Actualizar el lector desde la página ─────────────────────────────── */

static const char PAGINA_ACTUALIZAR[] =
    "<!doctype html><html lang='es'><head><meta charset='utf-8'><title>Actualizar lector</title>"
    "<style>body{font-family:system-ui,Segoe UI,sans-serif;background:#f0f4fb;color:#0f235a;display:flex;"
    "justify-content:center;align-items:center;height:100vh;margin:0}.c{background:#fff;padding:36px 44px;"
    "border-radius:18px;box-shadow:0 8px 30px #0f235a22;max-width:440px}button{background:#1B3B8C;color:#fff;"
    "border:0;border-radius:10px;padding:12px 22px;font-size:15px;cursor:pointer}button:disabled{opacity:.5}"
    "#m{margin-top:14px;font-weight:600}</style></head><body><div class='c'><h2>Actualizar el lector</h2>"
    "<p>Versión actual: <b>" VERSION "</b></p><p>Elige el archivo <b>lector-placa.bin</b> nuevo.</p>"
    "<p><input type='file' id='f' accept='.bin'></p><button id='b' onclick='subir()'>Actualizar</button>"
    "<div id='m'></div></div><script>"
    "async function subir(){const f=document.getElementById('f').files[0],m=document.getElementById('m'),"
    "b=document.getElementById('b');if(!f){m.textContent='Elige el archivo primero';return}"
    "b.disabled=true;m.style.color='#0f235a';m.textContent='Actualizando… no desenchufes el lector';"
    "try{const r=await fetch('/api/actualizar',{method:'POST',headers:{'Content-Type':'application/octet-stream'},body:f});"
    "const j=await r.json();if(!r.ok)throw new Error(j.detail||'Error');m.style.color='#16a34a';"
    "m.textContent='✓ Listo. El lector se reinicia en unos segundos.'}catch(e){m.style.color='#dc2626';"
    "m.textContent=e.message;b.disabled=false}}</script></body></html>";

static esp_err_t w_actualizar_pagina(httpd_req_t *req)
{
    PROHIBIDO(req);
    httpd_resp_set_type(req, "text/html; charset=utf-8");
    httpd_resp_set_hdr(req, "Cache-Control", "no-store");
    httpd_resp_set_hdr(req, "X-Frame-Options", "DENY");
    return httpd_resp_send(req, PAGINA_ACTUALIZAR, HTTPD_RESP_USE_STRLEN);
}

static void tarea_reiniciar(void *arg)
{
    vTaskDelay(pdMS_TO_TICKS(1500));
    esp_restart();
}

static esp_err_t w_actualizar(httpd_req_t *req)
{
    PROHIBIDO(req);
    if (S.estado != E_NINGUNA) {
        // Actualizar manda: la consulta que haya (o una conexión colgada) se corta.
        // El certificado nuevo, si llegó, ya está guardado: se usa tras actualizar.
        s_cert_nuevo = false;
        if (S.con_clave) {
            cJSON *m = cJSON_CreateObject();
            cJSON_AddStringToObject(m, "tipo", "fin");
            enviar_cifrado(m);
            cJSON_Delete(m);
        }
        terminar_sesion(true);
    }
    const esp_partition_t *destino = esp_ota_get_next_update_partition(NULL);
    if (!destino) return error(req, "500 Internal Server Error", "El lector no tiene espacio para actualizarse");
    if (req->content_len < 64 * 1024 || req->content_len > destino->size + 0x20000)
        return error(req, "400 Bad Request", "Ese archivo no es un programa del lector");
    esp_ota_handle_t ota;
    if (esp_ota_begin(destino, OTA_WITH_SEQUENTIAL_WRITES, &ota) != ESP_OK)
        return error(req, "500 Internal Server Error", "No se pudo empezar la actualización");
    // Sirve el .bin completo de Releases (arranque + tabla + programa desde 0x20000)
    // o solo el programa: se reconoce por la tabla de particiones en 0x8000.
    const size_t CABEZA = 0x8002, PROGRAMA = 0x20000;
    uint8_t *buf = malloc(CABEZA);
    if (!buf) { esp_ota_abort(ota); return error(req, "500 Internal Server Error", "Sin memoria"); }
    size_t total = req->content_len, leido = 0, saltar = 0;
    bool ok = true;
    size_t primero = total < CABEZA ? total : CABEZA;
    while (leido < primero) {
        int r = httpd_req_recv(req, (char *)buf + leido, primero - leido);
        if (r == HTTPD_SOCK_ERR_TIMEOUT) continue;
        if (r <= 0) { ok = false; break; }
        leido += r;
    }
    if (ok) {
        bool completo = total > PROGRAMA && buf[0] == 0xE9 && buf[0x8000] == 0xAA && buf[0x8001] == 0x50;
        if (completo) saltar = PROGRAMA;
        else if (esp_ota_write(ota, buf, leido) != ESP_OK) ok = false;
    }
    while (ok && leido < total) {
        int r = httpd_req_recv(req, (char *)buf, 4096);
        if (r == HTTPD_SOCK_ERR_TIMEOUT) continue;
        if (r <= 0) { ok = false; break; }
        if (leido + r > saltar) {
            size_t desde = leido < saltar ? saltar - leido : 0;
            if (esp_ota_write(ota, buf + desde, r - desde) != ESP_OK) ok = false;
        }
        leido += r;
    }
    free(buf);
    if (!ok) {
        esp_ota_abort(ota);
        return error(req, "400 Bad Request", "La actualización se interrumpió; el lector sigue con su versión actual");
    }
    esp_err_t fin = esp_ota_end(ota);    // aquí se revisa la firma de HypokratIA
    if (fin != ESP_OK) {
        ESP_LOGW(TAG, "Actualización rechazada (%s)", esp_err_to_name(fin));
        return error(req, "400 Bad Request", "Ese archivo no es un programa del lector firmado por HypokratIA");
    }
    if (esp_ota_set_boot_partition(destino) != ESP_OK)
        return error(req, "400 Bad Request", "Ese archivo no es un programa válido del lector");
    ESP_LOGI(TAG, "Actualización lista; reiniciando");
    responder(req, "200 OK", "{\"ok\":true}");
    xTaskCreate(tarea_reiniciar, "reiniciar", 2048, NULL, 5, NULL);
    return ESP_OK;
}

static const httpd_uri_t RUTAS[] = {
    { .uri = "/",                .method = HTTP_GET,  .handler = w_pagina },
    { .uri = "/api/estado",      .method = HTTP_GET,  .handler = w_estado },
    { .uri = "/api/aceptar",     .method = HTTP_POST, .handler = w_aceptar },
    { .uri = "/api/rechazar",    .method = HTTP_POST, .handler = w_rechazar },
    { .uri = "/api/terminar",    .method = HTTP_POST, .handler = w_terminar },
    { .uri = "/api/identificar", .method = HTTP_POST, .handler = w_identificar },
    { .uri = "/api/nota",        .method = HTTP_POST, .handler = w_nota },
    { .uri = "/api/idioma",      .method = HTTP_POST, .handler = w_idioma },
    { .uri = "/actualizar",      .method = HTTP_GET,  .handler = w_actualizar_pagina },
    { .uri = "/api/actualizar",  .method = HTTP_POST, .handler = w_actualizar },
};

static void registrar_rutas(httpd_handle_t srv)
{
    for (size_t i = 0; i < sizeof(RUTAS) / sizeof(RUTAS[0]); i++) httpd_register_uri_handler(srv, &RUTAS[i]);
}

// Con https activo, http solo redirige al nombre seguro
static esp_err_t w_a_https(httpd_req_t *req)
{
    char destino[160];
    int n = snprintf(destino, sizeof(destino), "https://%s", s_dominio);
    strlcpy(destino + n, req->uri, sizeof(destino) - n);   // la ruta, recortada si es muy larga
    httpd_resp_set_status(req, "301 Moved Permanently");
    httpd_resp_set_hdr(req, "Location", destino);
    return httpd_resp_send(req, "", 0);
}

static void iniciar_pagina(void)
{
    httpd_config_t cfg = HTTPD_DEFAULT_CONFIG();
    cfg.max_uri_handlers = 14;
    cfg.recv_wait_timeout = 30;
    cfg.send_wait_timeout = 30;
    cfg.lru_purge_enable = true;

    if (s_cert) {
        httpd_ssl_config_t ssl = HTTPD_SSL_CONFIG_DEFAULT();
        ssl.httpd = cfg;
        ssl.httpd.stack_size = 16384;
        ssl.httpd.max_open_sockets = 5;
        ssl.httpd.ctrl_port = 32770;
        ssl.servercert = (const uint8_t *)s_cert;
        ssl.servercert_len = strlen(s_cert) + 1;
        ssl.prvtkey_pem = (const uint8_t *)s_llave_pem;
        ssl.prvtkey_len = strlen(s_llave_pem) + 1;
        httpd_handle_t seguro = NULL;
        if (httpd_ssl_start(&seguro, &ssl) == ESP_OK) {
            registrar_rutas(seguro);
            httpd_config_t simple = HTTPD_DEFAULT_CONFIG();
            simple.uri_match_fn = httpd_uri_match_wildcard;
            simple.max_open_sockets = 3;
            httpd_handle_t srv = NULL;
            if (httpd_start(&srv, &simple) == ESP_OK) {
                const httpd_uri_t todo_get = { .uri = "/*", .method = HTTP_GET, .handler = w_a_https };
                httpd_register_uri_handler(srv, &todo_get);
            }
            xTaskCreate(tarea_dns, "dns", 4096, NULL, 4, NULL);
            ESP_LOGI(TAG, "Página segura: https://%s", s_dominio);
            return;
        }
        ESP_LOGE(TAG, "No partió https; se usa http");
        s_cert_estado = "https no partió";
        free(s_cert);
        s_cert = NULL;
    }
    cfg.stack_size = 12288;
    httpd_handle_t srv = NULL;
    ESP_ERROR_CHECK(httpd_start(&srv, &cfg));
    registrar_rutas(srv);
}

void app_main(void)
{
    esp_err_t r = nvs_flash_init();
    if (r == ESP_ERR_NVS_NO_FREE_PAGES || r == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        nvs_flash_erase();
        nvs_flash_init();
    }
    g_mutex = xSemaphoreCreateMutex();
    g_tx = xSemaphoreCreateMutex();
    g_rx_mutex = xSemaphoreCreateMutex();
    g_resp = xSemaphoreCreateBinary();
    g_escrito = xSemaphoreCreateBinary();

    cargar_identidad();
    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_AP_STAIPASSIGNED,
                                               pc_recibio_direccion, NULL));
    ESP_ERROR_CHECK(iniciar_red_usb());
    iniciar_pagina();

    xTaskCreate(tarea_procesar, "procesar", 12288, NULL, 5, &g_procesador);
    xTaskCreate(tarea_vigilante, "vigilante", 8192, NULL, 4, NULL);
    ESP_ERROR_CHECK(nimble_port_init());
    ble_hs_cfg.sync_cb = al_sincronizar;
    nimble_port_freertos_init(tarea_bluetooth);
    esp_ota_mark_app_valid_cancel_rollback();   // arrancó bien: se queda con esta versión
    ESP_LOGI(TAG, "Lector HypokratIA %s listo", VERSION);
}
