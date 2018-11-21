using System;

namespace USB
{
    public class USBInterface : IDisposable
    {
        /// <summary>HID Guid</summary>
        public Guid DeviceClassGuid { get; }

        /// <summary>Handle returned by RegisterForUsbEvents - need it when we unregister</summary>
        public IntPtr UsbEventHandle { get; set; }


        public USBInterface()
        {
            DeviceClassGuid = Win32Usb.HIDGuid;
        }

        /// <summary>Event called when a new device is detected</summary>
        public event EventHandler DeviceArrived;
        /// <summary>Event called when a device is removed</summary>
        public event EventHandler DeviceRemoved;

        /// <summary>
        /// Overridable 'On' method called when a new device is detected
        /// </summary>
        protected virtual void OnDeviceArrived(EventArgs args)
        {
            DeviceArrived?.Invoke(this, args);
        }
        /// <summary>
        /// Overridable 'On' method called when a device is removed
        /// </summary>
        protected virtual void OnDeviceRemoved(EventArgs args)
        {
            DeviceRemoved?.Invoke(this, args);
        }

        public void Dispose()
        {
            Win32Usb.UnregisterForUsbEvents(UsbEventHandle);
        }
    }
}
