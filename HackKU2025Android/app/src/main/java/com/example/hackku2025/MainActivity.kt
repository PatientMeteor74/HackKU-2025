package com.example.hackku2025

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.example.hackku2025.ui.theme.HackKU2025Theme
import java.util.Calendar

class MainActivity : ComponentActivity() {
    
    private val CHANNEL_ID = "test_channel"
    private val NOTIFICATION_ID = 1
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var runnable: Runnable
    
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            startMinuteNotifications()
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        createNotificationChannel()
        
        setContent {
            HackKU2025Theme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    HomePage(modifier = Modifier.padding(innerPadding))
                }
            }
        }
        
        checkNotificationPermission()
    }
    
    override fun onResume() {
        super.onResume()
        if (::runnable.isInitialized) {
            startMinuteNotifications()
        }
    }
    
    override fun onPause() {
        super.onPause()
        if (::runnable.isInitialized) {
            handler.removeCallbacks(runnable)
        }
    }
    
    private fun checkNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            when {
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) == PackageManager.PERMISSION_GRANTED -> {
                    startMinuteNotifications()
                }
                else -> {
                    requestPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                }
            }
        } else {
            startMinuteNotifications()
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Test Notifications"
            val descriptionText = "Channel for test notifications"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun startMinuteNotifications() {
        runnable = Runnable {
            val calendar = Calendar.getInstance()
            val seconds = calendar.get(Calendar.SECOND)
            
            // Calculate delay until the next minute
            val delayToNextMinute = if (seconds == 0) {
                // If we're exactly on the minute, send notification immediately and then wait a minute
                sendMinuteNotification()
                60 * 1000L
            } else {
                // Otherwise, calculate how long until next minute
                (60 - seconds) * 1000L
            }
            
            // Schedule the next check
            handler.postDelayed(runnable, delayToNextMinute)
        }
        
        // Start the initial check
        handler.post(runnable)
    }
    
    private fun sendMinuteNotification() {
        val calendar = Calendar.getInstance()
        val hour = calendar.get(Calendar.HOUR_OF_DAY)
        val minute = calendar.get(Calendar.MINUTE)
        
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Minute Notification")
            .setContentText("It's exactly $hour:${minute.toString().padStart(2, '0')}")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, builder.build())
    }
}

@Composable
fun HomePage(modifier: Modifier = Modifier) {
    // Dark gray background
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(Color(0xFF303030))
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // First panel - slightly less than 1/3
            Panel(
                modifier = Modifier
                    .weight(0.3f)
                    .fillMaxWidth()
            ) {
                Text("Panel 1", color = Color.White)
            }
            
            // Second panel - about half
            Panel(
                modifier = Modifier
                    .weight(0.5f)
                    .fillMaxWidth()
            ) {
                Text("Panel 2", color = Color.White)
            }
            
            // Third panel - remaining space
            Panel(
                modifier = Modifier
                    .weight(0.2f)
                    .fillMaxWidth()
            ) {
                Text("Panel 3", color = Color.White)
            }
        }
    }
}

@Composable
fun Panel(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    // Medium gray panel with rounded corners
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(Color(0xFF606060)),
        contentAlignment = Alignment.Center
    ) {
        content()
    }
}

@Preview(showBackground = true)
@Composable
fun HomePagePreview() {
    HackKU2025Theme {
        HomePage()
    }
}