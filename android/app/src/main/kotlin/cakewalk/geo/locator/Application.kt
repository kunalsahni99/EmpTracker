package cakewalk.geo.locator
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback
import io.flutter.plugins.pathprovider.PathProviderPlugin
import io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestorePlugin
import io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin
import io.flutter.view.FlutterMain
import rekab.app.background_locator.IsolateHolderService
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingPlugin
import io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin
import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin
class Application : FlutterApplication(), PluginRegistrantCallback {
    override fun onCreate() {
        super.onCreate()
        IsolateHolderService.setPluginRegistrant(this)
        FlutterMain.startInitialization(this)
    }

    override fun registerWith(registry: PluginRegistry?) {
        if (!registry!!.hasPlugin("io.flutter.plugins.pathprovider")) {
            PathProviderPlugin.registerWith(registry.registrarFor("io.flutter.plugins.pathprovider"))
        }
        if (!registry!!.hasPlugin("io.flutter.plugins.firebase.firestore")) {
            FlutterFirebaseFirestorePlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebase.firestore"))
        }
        if (!registry!!.hasPlugin("io.flutter.plugins.firebase.core")) {
            FlutterFirebaseCorePlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebase.core"))
        }
        if (!registry!!.hasPlugin("io.flutter.plugins.firebase.auth")) {
            FlutterFirebaseAuthPlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebase.auth"))
        }
        if (!registry!!.hasPlugin("io.flutter.plugins.firebase.messaging")) {
            FlutterFirebaseMessagingPlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebase.messaging"))
        }


    }
}
