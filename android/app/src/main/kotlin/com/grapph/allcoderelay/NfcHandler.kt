package com.grapph.allcoderelay

import android.app.Activity
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NfcHandler(private val activity: Activity, private val channel: MethodChannel) : NfcAdapter.ReaderCallback {
    private var nfcAdapter: NfcAdapter? = null
    
    init {
        nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    }
    
    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(nfcAdapter != null)
            "startSession" -> startSession(result)
            "stopSession" -> stopSession(result)
            else -> result.notImplemented()
        }
    }
    
    private fun startSession(result: MethodChannel.Result) {
        if (nfcAdapter == null) {
            result.error("UNAVAILABLE", "NFC not available", null)
            return
        }
        
        try {
            nfcAdapter?.enableReaderMode(activity, this, 
                NfcAdapter.FLAG_READER_NFC_A or 
                NfcAdapter.FLAG_READER_NFC_B or 
                NfcAdapter.FLAG_READER_NFC_F or 
                NfcAdapter.FLAG_READER_NFC_V, null)
            result.success(null)
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }
    
    private fun stopSession(result: MethodChannel.Result) {
        try {
            nfcAdapter?.disableReaderMode(activity)
            result.success(null)
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }
    
    override fun onTagDiscovered(tag: Tag) {
        val ndef = Ndef.get(tag)
        ndef?.let {
            val ndefMessage = it.cachedNdefMessage
            ndefMessage?.let { message ->
                if (message.records.isNotEmpty()) {
                    val record = message.records[0]
                    val payload = String(record.payload)
                    activity.runOnUiThread {
                        channel.invokeMethod("onTagRead", payload)
                    }
                }
            }
        }
    }
}