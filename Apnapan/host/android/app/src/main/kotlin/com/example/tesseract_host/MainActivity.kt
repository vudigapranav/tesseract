package com.example.tesseract_host

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.Surface
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterFragmentActivity(), EventChannel.StreamHandler, SensorEventListener {
    private val channelName = "org.tesseract/marble_tilt"
    private var sensorManager: SensorManager? = null
    private var rotationSensor: Sensor? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val hasGyroscope = sensorManager?.getDefaultSensor(Sensor.TYPE_GYROSCOPE) != null
        rotationSensor = if (hasGyroscope) {
            sensorManager?.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR)
                ?: sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        } else {
            null
        }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val sensor = rotationSensor
        if (sensor == null) {
            events.error("sensor_unavailable", "This phone has no rotation sensor.", null)
            return
        }
        eventSink = events
        sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
    }

    override fun onCancel(arguments: Any?) {
        sensorManager?.unregisterListener(this)
        eventSink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_GAME_ROTATION_VECTOR &&
            event.sensor.type != Sensor.TYPE_ROTATION_VECTOR
        ) return

        val rotation = FloatArray(9)
        SensorManager.getRotationMatrixFromVector(rotation, event.values)

        var x = rotation[6].toDouble()
        var y = -rotation[7].toDouble()
        @Suppress("DEPRECATION")
        if (windowManager.defaultDisplay.rotation == Surface.ROTATION_180) {
            x = -x
            y = -y
        }

        eventSink?.success(mapOf("x" to x, "y" to y))
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    override fun onPause() {
        sensorManager?.unregisterListener(this)
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
        val sink = eventSink
        val sensor = rotationSensor
        if (sink != null && sensor != null) {
            sensorManager?.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
        }
    }
}
