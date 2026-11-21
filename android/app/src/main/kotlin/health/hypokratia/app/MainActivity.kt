package health.hypokratia.app

// FlutterFragmentActivity: requerido por local_auth (huella / rostro)
import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Consulta sin conexión: el teléfono crea su propia red Wi-Fi local
 * (LocalOnlyHotspot, Android 8+). No da internet a nadie: solo deja que el
 * equipo del profesional abra la página que sirve la app. Android elige el
 * nombre y la clave de la red; se devuelven a Flutter para el QR.
 * Canal "misalud/red_local": iniciar → {ssid, clave} · detener.
 */
class MainActivity : FlutterFragmentActivity() {
    private var reserva: WifiManager.LocalOnlyHotspotReservation? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Nombre del equipo para la lista de teléfonos de confianza (p. ej. "Xiaomi Redmi Note 13")
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "misalud/equipo")
            .setMethodCallHandler { call, result ->
                if (call.method == "modelo") result.success(nombreEquipo()) else result.notImplemented()
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "misalud/red_local")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "iniciar" -> iniciar(result)
                    "detener" -> { detener(); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }

    private fun nombreEquipo(): String {
        val marca = (Build.MANUFACTURER ?: "").trim().replaceFirstChar { it.uppercase() }
        val modelo = (Build.MODEL ?: "").trim()
        val nombre = if (modelo.startsWith(marca, ignoreCase = true)) modelo else "$marca $modelo"
        return nombre.trim().take(80)
    }

    private fun iniciar(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("no_soportado", "Se necesita Android 8 o superior", null)
            return
        }
        detener()
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        var respondido = false
        try {
            wifi.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                override fun onStarted(r: WifiManager.LocalOnlyHotspotReservation) {
                    reserva = r
                    var ssid: String? = null
                    var clave: String? = null
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val c = r.softApConfiguration
                        ssid = if (Build.VERSION.SDK_INT >= 33) {
                            c.wifiSsid?.toString()?.trim('"')
                        } else {
                            @Suppress("DEPRECATION") c.ssid
                        }
                        clave = c.passphrase
                    } else {
                        @Suppress("DEPRECATION") val c = r.wifiConfiguration
                        ssid = c?.SSID?.trim('"')
                        @Suppress("DEPRECATION")
                        clave = c?.preSharedKey?.trim('"')
                    }
                    if (!respondido) {
                        respondido = true
                        result.success(mapOf("ssid" to ssid, "clave" to clave))
                    }
                }

                override fun onFailed(reason: Int) {
                    if (!respondido) {
                        respondido = true
                        result.error("fallo", "No se pudo crear la red local (código $reason)", null)
                    }
                }

                override fun onStopped() {
                    reserva = null
                }
            }, Handler(Looper.getMainLooper()))
        } catch (e: SecurityException) {
            if (!respondido) { respondido = true; result.error("permiso", e.message, null) }
        } catch (e: IllegalStateException) {
            if (!respondido) { respondido = true; result.error("fallo", e.message, null) }
        }
    }

    private fun detener() {
        reserva?.close()
        reserva = null
    }

    override fun onDestroy() {
        detener()
        super.onDestroy()
    }
}
