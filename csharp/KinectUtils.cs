using System;
using Godot;
using Microsoft.Azure.Kinect.Sensor;

namespace godotkinect.csharp;

public class KinectUtils
{
	private static readonly Basis RotationOffset = Basis.FromEuler(new Vector3(0, Mathf.Pi, 0));

	public static Func<ImuSample, Basis> CreateImuReader()
	{
		TimeSpan lastGyroTimestamp = TimeSpan.Zero;
		var stableUpVector = Vector3.Up;
		return sample => {
			var delta = (float) sample.GyroTimestamp.Subtract(lastGyroTimestamp).TotalSeconds;
			lastGyroTimestamp = sample.GyroTimestamp;

			var acceleration = RotationOffset * new Vector3(
				-sample.AccelerometerSample.Y,
				-sample.AccelerometerSample.Z,
				sample.AccelerometerSample.X
			);
			var gyro = RotationOffset * new Vector3(
				-sample.GyroSample.Y,
				0,
				sample.GyroSample.X
			);

			var gyroRotationDelta = delta * gyro;
			var gyroRotation = Basis.FromEuler(gyroRotationDelta);
			var upFromGyro = (gyroRotation * stableUpVector).Normalized();
			var upFromAccel = acceleration.Normalized();
			stableUpVector = upFromGyro.Slerp(upFromAccel, 0.02f);

			var yAxis = stableUpVector.Normalized();
			var fwdAnchor = Vector3.Forward;
			if (Math.Abs(yAxis.Dot(fwdAnchor)) > 0.99)
			{
				fwdAnchor = Vector3.Right;
			}
			var xAxis = fwdAnchor.Cross(yAxis).Normalized();
			var zAxis = xAxis.Cross(yAxis).Normalized();

			return new Basis(xAxis, yAxis, zAxis);
		};
	}
	
	public static Godot.Image ReadDepth(Capture capture, float minDepth, float maxDepth)
	{
		var depthImage = capture.Depth;
		if (depthImage == null)
		{
			return null;
		}
		
		var depthRange = maxDepth - minDepth;
		var depthData = depthImage.Memory.ToArray();
		var width = depthImage.WidthPixels;
		var height = depthImage.HeightPixels;
		var numPixels = width * height;
		
		var grayscaleData = new byte[numPixels * 6];
		
		for (var i = 0; i < numPixels; i++)
		{
			var inputIndex = i * 2;
			var currentDepthMm = (ushort)(depthData[inputIndex] | (depthData[inputIndex + 1] << 8));
			Half grayValueHalf;
			if (currentDepthMm == 0)
			{
				grayValueHalf = (Half)0;
			}
			else
			{
				var clampedDepth = Math.Max(minDepth, Math.Min(maxDepth, currentDepthMm));
				var normalizedDepth = 1.0f - (clampedDepth - minDepth) / depthRange;
				grayValueHalf = (Half)normalizedDepth;
			}
			var halfBytes = BitConverter.GetBytes(grayValueHalf);
			
			
			var outputIndex = i * 6;
			Array.Copy(halfBytes, 0, grayscaleData, outputIndex, 2);
			Array.Copy(halfBytes, 0, grayscaleData, outputIndex + 2, 2);
			Array.Copy(halfBytes, 0, grayscaleData, outputIndex + 4, 2);
		}

		return Godot.Image.CreateFromData(width, height, false, Godot.Image.Format.Rgbh, grayscaleData);

	}

	public static Godot.Image ReadColor(Capture capture)
	{
		var colorImage = capture.Color;
		if (colorImage == null)
		{
			return null;
		}

		var colorData = colorImage.Memory.ToArray();
		var width = colorImage.WidthPixels;
		var height = colorImage.HeightPixels;
		var numPixels = width * height;
					
		var rgbData = new byte[numPixels * 3];

		for (var i = 0; i < numPixels; i++)
		{
			var inputIndex = i * 4;
			var b = colorData[inputIndex];
			var g = colorData[inputIndex + 1];
			var r = colorData[inputIndex + 2];
			var outputIndex = i * 3;
			rgbData[outputIndex] = r;
			rgbData[outputIndex + 1] = g;
			rgbData[outputIndex + 2] = b;
		}

		return Godot.Image.CreateFromData(width, height, false, Godot.Image.Format.Rgb8, rgbData);
	}
}
