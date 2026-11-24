/*
 * herramientas/lector_placa/main/main.c — Lector HypokratIA en placa ESP32-S3
 *
 * Prueba 1: al enchufar la placa al PC por su puerto "USB", Windows la ve como
 * una tarjeta de red (USB NCM, sin instalar drivers). La placa le da una
 * dirección al PC (DHCP) y sirve una página en http://192.168.4.1
 *
 * No se ofrece "puerta de enlace" ni DNS: el PC sigue usando su internet
 * normal (si lo tiene) y solo habla con la placa en 192.168.4.x.
 *
 * Basado en el ejemplo de Espressif examples/network/sta2eth (usb_ncm_iface.c).
 * Siguientes pruebas: abrir la página sola (teclado USB) y Bluetooth con la app.
 */
#include <string.h>
#include <stdlib.h>
#include "esp_log.h"
#include "esp_event.h"
#include "esp_netif.h"
#include "esp_http_server.h"
#include "nvs_flash.h"
#include "tinyusb.h"
#include "tinyusb_net.h"
#include "dhcpserver/dhcpserver_options.h"
#include "lwip/esp_netif_net_stack.h"

static const char *TAG = "lector";
static esp_netif_t *s_netif = NULL;

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

static esp_err_t iniciar_red_usb(void)
{
    const tinyusb_config_t tusb_cfg = { .external_phy = false };
    ESP_ERROR_CHECK(tinyusb_driver_install(&tusb_cfg));

    const tinyusb_net_config_t net_cfg = {
        .mac_addr = {0x02, 0x48, 0x4B, 0x00, 0x00, 0x01},   // tarjeta que ve el PC
        .on_recv_callback = recibido_del_pc,
    };
    ESP_ERROR_CHECK(tinyusb_net_init(TINYUSB_USBDEV_0, &net_cfg));

    static const esp_netif_ip_info_t ip = {
        .ip      = { .addr = ESP_IP4TOADDR(192, 168, 4, 1) },
        .gw      = { .addr = ESP_IP4TOADDR(192, 168, 4, 1) },
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
    dhcps_offer_t sin_router = 0;
    esp_netif_dhcps_option(s_netif, ESP_NETIF_OP_SET, ESP_NETIF_ROUTER_SOLICITATION_ADDRESS,
                           &sin_router, sizeof(sin_router));
    uint32_t arriendo = 1;   // minutos
    esp_netif_dhcps_option(s_netif, ESP_NETIF_OP_SET, IP_ADDRESS_LEASE_TIME,
                           &arriendo, sizeof(arriendo));

    esp_netif_action_start(s_netif, 0, 0, 0);
    ESP_LOGI(TAG, "Red USB lista: http://192.168.4.1");
    return ESP_OK;
}

/* ── Página ───────────────────────────────────────────────────────────── */

static const char PAGINA[] =
    "<!doctype html><html lang='es'><head><meta charset='utf-8'>"
    "<meta name='viewport' content='width=device-width,initial-scale=1'>"
    "<title>Lector HypokratIA</title>"
    "<style>body{margin:0;font-family:system-ui,Segoe UI,sans-serif;background:#f0f4fb;"
    "display:flex;align-items:center;justify-content:center;height:100vh;color:#0f235a}"
    ".c{background:#fff;padding:40px 48px;border-radius:18px;box-shadow:0 8px 30px #0f235a22;text-align:center}"
    "h1{margin:0 0 8px}p{color:#334155;margin:6px 0}.ok{color:#16a34a;font-weight:700}</style>"
    "</head><body><div class='c'><h1>Hola HypokratIA</h1>"
    "<p class='ok'>✓ El lector está conectado a este computador por USB</p>"
    "<p>Sin internet, sin programas y sin drivers.</p></div></body></html>";

static esp_err_t pagina_inicio(httpd_req_t *req)
{
    httpd_resp_set_type(req, "text/html; charset=utf-8");
    httpd_resp_set_hdr(req, "Cache-Control", "no-store");
    return httpd_resp_send(req, PAGINA, HTTPD_RESP_USE_STRLEN);
}

static void iniciar_pagina(void)
{
    httpd_handle_t srv = NULL;
    httpd_config_t cfg = HTTPD_DEFAULT_CONFIG();
    ESP_ERROR_CHECK(httpd_start(&srv, &cfg));
    const httpd_uri_t inicio = { .uri = "/", .method = HTTP_GET, .handler = pagina_inicio };
    httpd_register_uri_handler(srv, &inicio);
}

void app_main(void)
{
    esp_err_t r = nvs_flash_init();
    if (r == ESP_ERR_NVS_NO_FREE_PAGES || r == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        nvs_flash_erase();
        nvs_flash_init();
    }
    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    ESP_ERROR_CHECK(iniciar_red_usb());
    iniciar_pagina();
}
