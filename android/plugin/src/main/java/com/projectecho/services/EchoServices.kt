package com.projectecho.services

import android.content.Intent
import android.os.Bundle
import androidx.core.content.FileProvider
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.analytics.FirebaseAnalytics
import com.revenuecat.purchases.CustomerInfo
import com.revenuecat.purchases.Package
import com.revenuecat.purchases.PurchaseParams
import com.revenuecat.purchases.Purchases
import com.revenuecat.purchases.PurchasesConfiguration
import com.revenuecat.purchases.getCustomerInfoWith
import com.revenuecat.purchases.getOfferingsWith
import com.revenuecat.purchases.purchaseWith
import com.revenuecat.purchases.restorePurchasesWith
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONObject
import java.io.File

/** Narrow native boundary: verified purchases, optional analytics, and image sharing. */
class EchoServices(godot: Godot) : GodotPlugin(godot) {
    private var offering: Package? = null
    private var configured = false
    private var analytics: FirebaseAnalytics? = null
    private var analyticsEnabled = false
    private var transactionInFlight = false

    override fun getPluginName() = "EchoServices"
    override fun getPluginSignals() = setOf(
        SignalInfo("offer_loaded", String::class.java),
        SignalInfo("entitlement_changed", Boolean::class.javaObjectType),
        SignalInfo("purchase_state", String::class.java, String::class.java)
    )

    @UsedByGodot
    fun configure_services(configuration: String): Boolean {
        val host = activity ?: return false
        val config = try { JSONObject(configuration) } catch (_: Exception) { return false }
        val key = config.optString("revenuecat_android_api_key")
        host.runOnUiThread {
            try {
                if (key.isNotBlank() && !configured) {
                    Purchases.configure(PurchasesConfiguration.Builder(host.applicationContext, key).build())
                    configured = true
                    refreshPurchases()
                }
                val appId = config.optString("firebase_app_id")
                val apiKey = config.optString("firebase_api_key")
                val project = config.optString("firebase_project_id")
                if (appId.isNotBlank() && apiKey.isNotBlank() && project.isNotBlank()) {
                    if (FirebaseApp.getApps(host).isEmpty()) {
                        FirebaseApp.initializeApp(host, FirebaseOptions.Builder()
                            .setApplicationId(appId).setApiKey(apiKey).setProjectId(project).build())
                    }
                    analytics = FirebaseAnalytics.getInstance(host)
                    analytics?.setAnalyticsCollectionEnabled(analyticsEnabled)
                }
            } catch (_: Exception) {
                status("error", "The store could not connect. Please try again later.")
            }
        }
        return key.isNotBlank()
    }

    private fun refreshPurchases() {
        Purchases.sharedInstance.getCustomerInfoWith(
            onError = { /* Keep SDK's cached entitlement when offline. */ },
            onSuccess = { updateEntitlement(it) }
        )
        Purchases.sharedInstance.getOfferingsWith(
            onError = { emitSignal("offer_loaded", "") },
            onSuccess = { offerings ->
                offering = offerings.current?.availablePackages?.firstOrNull {
                    it.product.id == "echo_supporter"
                }
                emitSignal("offer_loaded", offering?.product?.price?.formatted.orEmpty())
            }
        )
    }

    @UsedByGodot
    fun purchase_supporter() {
        val host = activity ?: return
        host.runOnUiThread {
            val selected = offering
            if (!configured || selected == null || transactionInFlight) {
                status("error", "The store is not ready. Please try again.")
                return@runOnUiThread
            }
            transactionInFlight = true
            Purchases.sharedInstance.purchaseWith(
                PurchaseParams.Builder(host, selected).build(),
                onError = { error, cancelled ->
                    transactionInFlight = false
                    val pending = error.code.name == "PaymentPendingError"
                    status(if (pending) "deferred" else "error", when {
                        cancelled -> "Purchase cancelled. You have not been charged."
                        pending -> "Payment is pending. Your pack unlocks after confirmation."
                        else -> "The purchase could not be completed. Please try again."
                    })
                },
                onSuccess = { _, info ->
                    transactionInFlight = false
                    updateEntitlement(info)
                    status("complete", if (info.entitlements["supporter"]?.isActive == true)
                        "Thank you! Your Supporter Pack is unlocked."
                    else "Your purchase is being confirmed. Use Restore if it doesn't appear.")
                }
            )
        }
    }

    @UsedByGodot
    fun restore_purchases() {
        activity?.runOnUiThread {
            if (!configured || transactionInFlight) {
                status("error", "The store is not ready. Please try again.")
                return@runOnUiThread
            }
            transactionInFlight = true
            Purchases.sharedInstance.restorePurchasesWith(
                onError = {
                    transactionInFlight = false
                    status("error", "Could not restore purchases. Check your connection and try again.")
                },
                onSuccess = { info ->
                    transactionInFlight = false
                    updateEntitlement(info)
                    status("complete", if (info.entitlements["supporter"]?.isActive == true)
                        "Your Supporter Pack has been restored."
                    else "No Supporter Pack was found for this Google Play account.")
                }
            )
        }
    }

    override fun onMainResume() {
        super.onMainResume()
        if (configured) activity?.runOnUiThread { refreshPurchases() }
    }

    private fun updateEntitlement(info: CustomerInfo) {
        emitSignal("entitlement_changed", info.entitlements["supporter"]?.isActive == true)
    }
    private fun status(state: String, text: String) = emitSignal("purchase_state", state, text)

    @UsedByGodot
    fun set_analytics_enabled(enabled: Boolean) {
        analyticsEnabled = enabled
        activity?.runOnUiThread { analytics?.setAnalyticsCollectionEnabled(enabled) }
    }

    @UsedByGodot
    fun log_event(name: String, properties: String) {
        if (!analyticsEnabled || !name.matches(Regex("[a-z][a-z0-9_]{0,39}"))) return
        val source = try { JSONObject(properties) } catch (_: Exception) { return }
        val allowed = setOf("mode", "rules_version", "score", "sparks", "duration", "death_cause", "echoes")
        val bundle = Bundle()
        source.keys().forEach { key ->
            if (key in allowed) when (val value = source.get(key)) {
                is Int -> bundle.putLong(key, value.toLong())
                is Long -> bundle.putLong(key, value)
                is Double -> bundle.putDouble(key, value)
                is String -> bundle.putString(key, value.take(80))
            }
        }
        activity?.runOnUiThread { analytics?.logEvent(name, bundle) }
    }

    @UsedByGodot
    fun share_score(path: String) {
        val host = activity ?: return
        host.runOnUiThread {
            try {
                val file = File(path).canonicalFile
                // Only the generated score card may cross the Android file boundary.
                require(file.name == "echo-score.png" && file.toPath().startsWith(host.filesDir.canonicalFile.toPath()))
                val uri = FileProvider.getUriForFile(host, "${host.packageName}.echo.files", file)
                val share = Intent(Intent.ACTION_SEND).apply {
                    type = "image/png"
                    putExtra(Intent.EXTRA_STREAM, uri)
                    putExtra(Intent.EXTRA_TEXT, "Can you outrun yourself? Project ECHO")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                host.startActivity(Intent.createChooser(share, "Share your ECHO score"))
            } catch (_: Exception) {
                status("error", "Your score card could not be shared. Please try again.")
            }
        }
    }
}
