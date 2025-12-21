using System;
using Godot;
using Microsoft.Azure.Kinect.BodyTracking;
using Microsoft.Azure.Kinect.Sensor;
using Image = Godot.Image;

namespace godotkinect.csharp;

[GlobalClass]
public partial class Kinect : RefCounted
{
	private KinectHooks _hooks;
	private KinectHooks _imuHooks;
	private Device _kinectDevice;
	private Basis _orientation = Basis.Identity;
	private KinectHooks _tracker;

	public bool IsRunning => _hooks is { IsRunning: true };
	public Basis Orientation => _orientation;

	public void Initialize(int device = 0)
	{
		if (Device.GetInstalledCount() == 0)
		{
			GD.PrintErr("No Azure Kinect devices found.");
			return;
		}

		_kinectDevice = Device.Open(device);
	}

	protected override void Dispose(bool disposing)
	{
		Stop();
		StopImu();
		_kinectDevice?.Dispose();
		base.Dispose(disposing);
	}

	private void StartImu()
	{
		if (_kinectDevice == null)
		{
			GD.Print("Kinect device not initialized.");
			return;
		}

		_kinectDevice?.StartImu();
		var imuReader = KinectUtils.CreateImuReader();
		_imuHooks = KinectHooks.StartImu(_kinectDevice, sample => _orientation = imuReader(sample));
	}

	private void StopImu()
	{
		_imuHooks?.Dispose();
		_imuHooks = null;
		_kinectDevice?.StopImu();
	}

	public void Start(KinectTracker kinectTracker, ImageTexture texture, float minDepth = 50, float maxDepth = 5000,
		bool isColor = false, bool enableImu = false)
	{
		if (_kinectDevice == null)
		{
			GD.Print("Kinect device not initialized.");
			return;
		}

		Stop();

		GD.Print("Starting Azure Kinect...");

		var config = new DeviceConfiguration
		{
			ColorFormat = ImageFormat.ColorBGRA32,
			ColorResolution = isColor ? ColorResolution.R720p : ColorResolution.Off,
			DepthMode = isColor ? DepthMode.Off : DepthMode.NFOV_Unbinned,
			CameraFPS = FPS.FPS30,
			SynchronizedImagesOnly = false
		};

		_kinectDevice.StartCameras(config);
		GD.Print("Azure Kinect camera started.");


		var trackerConfig = new TrackerConfiguration
		{
			SensorOrientation = SensorOrientation.Default,
			ProcessingMode = TrackerProcessingMode.Gpu
		};

		Tracker tracker = null;
		if (kinectTracker != null)
		{
			tracker = Tracker.Create(_kinectDevice.GetCalibration(), trackerConfig);
			_tracker = KinectHooks.StartTracker(tracker, frame =>
			{
				var positions = new Vector3[frame.NumberOfBodies];
				for (uint i = 0; i < frame.NumberOfBodies; i++)
				{
					var skeleton = frame.GetBodySkeleton(i);
					var neck = skeleton.GetJoint(JointId.Neck);
					var center = neck.Position / 1000;
					positions[i] = _orientation * new Vector3(center.X, -center.Y, -center.Z);
				}

				try
				{
					CallDeferred(nameof(UpdateTrackedBodies), kinectTracker, positions);
				}
				catch (ObjectDisposedException e)
				{
					GD.Print("Tracker has been disposed.");
				}
			});
		}

		_hooks = KinectHooks.StartCapture(_kinectDevice, capture =>
		{
			tracker?.EnqueueCapture(capture);

			if (texture == null) return;

			var image = isColor ? KinectUtils.ReadColor(capture) : KinectUtils.ReadDepth(capture, minDepth, maxDepth);
			try
			{
				CallDeferred(nameof(ApplyImage), texture, image);
			}
			catch (ObjectDisposedException e)
			{
				GD.Print("Texture has been disposed.");
			}
		});

		if (enableImu) StartImu();
	}

	private void StopTracker()
	{
		_tracker?.Dispose();
		_tracker = null;
	}

	public void Stop()
	{
		StopImu();
		StopTracker();

		_hooks?.Dispose();
		_hooks = null;

		GD.Print("Stopping Azure Kinect camera.");
		_kinectDevice?.StopCameras();
	}

	private static void UpdateTrackedBodies(KinectTracker kinectTracker, Vector3[] positions)
	{
		kinectTracker?.UpdateBodies(positions);
	}

	private static void ApplyImage(ImageTexture texture, Image image)
	{
		if (image == null) return;

		if (texture.GetWidth() == image.GetWidth() &&
			texture.GetHeight() == image.GetHeight() &&
			texture.GetFormat() == image.GetFormat())
			texture?.Update(image);
		else
			texture?.SetImage(image);
	}
}
