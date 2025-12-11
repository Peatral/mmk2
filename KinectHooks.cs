using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Azure.Kinect.BodyTracking;
using Microsoft.Azure.Kinect.Sensor;

namespace godotkinect;

public class KinectHooks: IDisposable
{
    private readonly CancellationTokenSource _cancellationToken = new();

    private KinectHooks()
    {
    }

    public static KinectHooks StartTracker(Tracker tracker, Action<Frame> action)
    {
        return Start(() =>
        {
            var frame = tracker.PopResult(TimeSpan.FromMilliseconds(500));
            if (frame == null)
            {
                return;
            }
            action.Invoke(frame);
        });
    }
    
    public static KinectHooks StartImu(Device device, Action<ImuSample> action)
    {
        return Start(() => {
            var sample = device.GetImuSample(TimeSpan.FromMilliseconds(1000));
            if (sample == null)
            {
                return;
            }
            action.Invoke(sample);
        });
    }
    
    public static KinectHooks StartCapture(Device device, Action<Capture> action)
    {
        return Start(() => {
            using var capture = device.GetCapture(TimeSpan.FromMilliseconds(1000));
            if (capture == null)
            {
                return;
            }
            action.Invoke(capture);
        });
    }
    
    private static KinectHooks Start(Action action)
    {
        var kinectCapture = new KinectHooks();
        Task.Run(
            () => CaptureLoop(
                action.Invoke,
                kinectCapture._cancellationToken.Token
            ),
            kinectCapture._cancellationToken.Token
        );
        return kinectCapture;
    }

    public void Dispose()
    {
        Stop();
        _cancellationToken.Dispose();
        GC.SuppressFinalize(this);
    }

    public void Stop()
    {
        _cancellationToken?.Cancel();
    }

    public bool IsRunning => !_cancellationToken.IsCancellationRequested;

    private static void CaptureLoop(Action action, CancellationToken cancellationToken)
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            action.Invoke();
        }
    }
}