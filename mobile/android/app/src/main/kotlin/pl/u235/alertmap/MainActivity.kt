package pl.u235.alertmap

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Wymuszamy edge-to-edge — apka rysuje POD status barem i nav barem.
        // Bez tego Samsung One UI / Android 14+ wymusza biały/szary scrim pod ikonami.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pl.u235.alertmap/update")
            .setMethodCallHandler { call, result ->
                if (call.method == "openUrl") {
                    val url = call.arguments as String
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
