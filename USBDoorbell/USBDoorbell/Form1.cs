using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Windows.Forms;
using USB;

namespace USBDoorbell
{
    public partial class Form1 : Form
    {
        private const int NUMSOUNDS = 5;

        private NotifyIcon  trayIcon;
        private ContextMenu trayMenu;
        private List<MenuItem> soundItems;
        private Icon connectedIcon;
        private Icon disconnectedIcon;
        private Icon mutedIcon;
  
        private USBDevice device;
        private Guid deviceClassGuid;
        private IntPtr usbEventHandle;
        private System.Media.SoundPlayer player;
        private System.Timers.Timer timerBell = new System.Timers.Timer();
        private bool isPlaying = false;
        private bool isConnected = false;
        private bool isMuted = false;
        private string path;

        public Form1()
        {
            InitializeComponent();
            deviceClassGuid = Win32Usb.HIDGuid;
            path = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            connectedIcon = new Icon(System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream("USBDoorbell.Resources.goldBell.ico"));
            disconnectedIcon = new Icon(System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream("USBDoorbell.Resources.greyBell.ico"));
            mutedIcon = new Icon(System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream("USBDoorbell.Resources.muteBell.ico"));

            soundItems = new List<MenuItem>{
                new MenuItem("Ding Dong", OnDingDong),
                new MenuItem("Ding Dong Ding Dong", OnDingDong2),
                new MenuItem("Buzzer", OnBuzzer),
                new MenuItem("Ring Ring", OnRingRing),
                new MenuItem("Mute", OnMute)
            };

            trayMenu = new ContextMenu();
            trayMenu.MenuItems.Add("Test Bell", OnTestBell);
            trayMenu.MenuItems.Add("Choose Bell Sound", soundItems.ToArray());
            trayMenu.MenuItems.Add("Open Log", OnLog);
            trayMenu.MenuItems.Add("Exit", OnExit);
 
            trayIcon = new NotifyIcon();
            trayIcon.Text = "Doorbell Monitor";
            trayIcon.Icon = disconnectedIcon;
            trayIcon.ContextMenu = trayMenu;
            trayIcon.Visible     = true;

            player = new System.Media.SoundPlayer(System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream(@"USBDoorbell.Media.DingDong2.wav"));
            soundItems[1].Checked = true;
            timerBell.Interval = 2000;
            timerBell.Elapsed += new System.Timers.ElapsedEventHandler(bellTimer_Tick);
            isConnected = Connect();
            ShowStatus();
        }

        private static void SetLabelText(Label label, string text)
        {
            label.Text = text;
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            usbEventHandle = Win32Usb.RegisterForUsbEvents(Handle, deviceClassGuid);
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == Win32Usb.WM_DEVICECHANGE) 
            {
                switch (m.WParam.ToInt32()) 
                {
                    case Win32Usb.DEVICE_ARRIVAL:
                        DeviceArrived();
                        break;
                    case Win32Usb.DEVICE_REMOVECOMPLETE:
                        DeviceRemoved();
                        break;
                }
            }
            base.WndProc(ref m);
        }

        protected override void OnLoad(EventArgs e)
        {
            Visible = false;
            ShowInTaskbar = false;
            base.OnLoad(e);
        }

        private void OnExit(object sender, EventArgs e)
        {
            trayIcon.Dispose();
            Application.Exit();
        }

        private bool Connect()
        {
            device = USBDevice.FindDevice();
            if (device != null)
            {
                device.OnButtonChanged += Button_Press;
                return true;
            }
            return false;
        }

        private void ShowStatus()
        {
            if (isConnected)
            {
                label1.Visible = false;
                if (!isMuted) trayIcon.Icon = connectedIcon;
                else trayIcon.Icon = mutedIcon;
            }
            else
            {
                label1.Visible = true;
                trayIcon.Icon = disconnectedIcon;
            }
        }

        private void Button_Press(object sender, EventArgs e)
        {
            RingBell();
        }

        private void RingBell()
        {
            if (!isPlaying)
            {
                isPlaying = true;
                trayIcon.ShowBalloonTip(3600000, "Door!!!", "There's somebody at the door!", ToolTipIcon.Info);
                player.Play();
                WriteLog();
                timerBell.Start();
            }
        }

        private void WriteLog()
        {
            try
            {
                Directory.CreateDirectory(path + "\\Doorbell");
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.ToString(), "Error!", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            using(TextWriter tw = new StreamWriter(path + "\\Doorbell\\log.txt", true))
            {
                tw.WriteLine(DateTime.Now);
            }
                
        }

        private void DeviceArrived()
        {
            if (!isConnected) isConnected = Connect();
            ShowStatus();
        }

        private void DeviceRemoved()
        {
            isConnected = USBDevice.CheckPresent();
            ShowStatus();
        }

        private void UncheckAllSoundItems()
        {
            foreach( var item in soundItems)
            {
                item.Checked = false;
            }
        }

        #region Sound Choice Events

        protected void OnDingDong(object sender, EventArgs e)
        {
            player = new System.Media.SoundPlayer(System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream(@"USBDoorbell.Media.DingDong.wav"));
            UncheckAllSoundItems();
            soundItems[0].Checked = true;
            isMuted = false;
            ShowStatus();
        }

        protected void OnDingDong2(object sender, EventArgs e)
        {
            player = new System.Media.SoundPlayer(System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream(@"USBDoorbell.Media.DingDong2.wav"));
            UncheckAllSoundItems();
            soundItems[1].Checked = true;
            isMuted = false;
            ShowStatus();
        }

        protected void OnBuzzer(object sender, EventArgs e)
        {
            player = new System.Media.SoundPlayer(System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream(@"USBDoorbell.Media.Buzzer.wav"));
            UncheckAllSoundItems();
            soundItems[2].Checked = true;
            isMuted = false;
            ShowStatus();
        }

        protected void OnRingRing(object sender, EventArgs e)
        {
            player = new System.Media.SoundPlayer(System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream(@"USBDoorbell.Media.RingRing.wav"));
            UncheckAllSoundItems();
            soundItems[3].Checked = true;
            isMuted = false;
            ShowStatus();
        }

        protected void OnMute(object sender, EventArgs e)
        {
            player = new System.Media.SoundPlayer(System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream(@"Doorbell.Media.Silence.wav"));
            UncheckAllSoundItems();
            soundItems[4].Checked = true;
            isMuted = true;
            ShowStatus();
        }

        #endregion

        protected void OnLog(object sender, EventArgs e)
        {
            if (!Directory.Exists(path + "\\Doorbell"))
            {
                Directory.CreateDirectory(path + "\\Doorbell");               
            }
            if (!File.Exists(path + "\\Doorbell\\log.txt"))
            {
                File.Create(path + "\\Doorbell\\log.txt");
            }
            else Process.Start(path + "\\Doorbell\\log.txt");
        }

        protected void OnTestBell(object sender, EventArgs e)
        {
            player.Play();
        }
 
        void bellTimer_Tick(object sender, EventArgs e)
        {
            timerBell.Stop();
            isPlaying = false;
        }

        private void OnTestButton(object sender, EventArgs e)
        {
            WriteLog();
        }

    }
}
