package com.chatsimulator.chat_simulator_pro

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.content.Intent

class ChatSimulatorAccessibilityService : AccessibilityService() {

    companion object {
        var instance: ChatSimulatorAccessibilityService? = null
        var pendingText: String? = null
        
        fun isEnabled(): Boolean {
            return instance != null
        }
        
        fun simulateType(text: String) {
            pendingText = text
            // Try to immediately type if there is a focused view
            instance?.typePendingText()
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_VIEW_FOCUSED or AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.DEFAULT or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
        this.serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        if (event.eventType == AccessibilityEvent.TYPE_VIEW_FOCUSED || event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            typePendingText()
        }
    }

    fun typePendingText() {
        val text = pendingText ?: return
        val rootNode = rootInActiveWindow ?: return
        val focusedNode = rootNode.findFocus(AccessibilityNodeInfo.FOCUS_INPUT) ?: return
        
        if (focusedNode.className == "android.widget.EditText" || focusedNode.isEditable) {
            val arguments = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
            }
            focusedNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
            pendingText = null // Consume it
            
            // Try to find and click send button in chat applications
            clickSendButton(rootNode)
        }
    }

    private fun clickSendButton(rootNode: AccessibilityNodeInfo) {
        // Search for node containing "Send" or Urdu "بھیجیں" or specific icon
        val textSendNodes = rootNode.findAccessibilityNodeInfosByText("Send")
        if (textSendNodes != null && textSendNodes.isNotEmpty()) {
            for (node in textSendNodes) {
                if (node.isClickable) {
                    node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    return
                }
                var parent = node.parent
                while (parent != null) {
                    if (parent.isClickable) {
                        parent.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                        return
                    }
                    parent = parent.parent
                }
            }
        }

        val urduSendNodes = rootNode.findAccessibilityNodeInfosByText("بھیجیں")
        if (urduSendNodes != null && urduSendNodes.isNotEmpty()) {
            for (node in urduSendNodes) {
                if (node.isClickable) {
                    node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    return
                }
                var parent = node.parent
                while (parent != null) {
                    if (parent.isClickable) {
                        parent.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                        return
                    }
                    parent = parent.parent
                }
            }
        }
    }

    override fun onInterrupt() {
        // No-op
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
    }
}
