using System;

namespace USB
{
    public class ButtonStates
    {
        public bool Inp1;
        public bool Inp2;
        public bool Inp3;
        public bool Inp4;
        public bool Inp5;
    }

    public class ButtonChangedEventArgs : EventArgs
    {
        /// <summary>Current states of the buttons</summary>
        public readonly ButtonStates Buttons;
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="buttons">State of the buttons</param>
        public ButtonChangedEventArgs(ButtonStates buttons)
        {
            Buttons = buttons;
        }
    }

    /// <summary>
    /// Delegate for button event
    /// </summary>
    public delegate void ButtonChangedEventHandler(object sender, ButtonChangedEventArgs args);


    public class USBDevice : HIDDevice
    {
        private const int VID = 0x04d8; //0x10cf;// ***
        private const int PID = 0xCC77; //0x5500;// ***

        private Byte mButtons;
        public event ButtonChangedEventHandler OnButtonChanged;

        public override InputReport CreateInputReport()
        {
            return new MyInputReport(this);
        }

        public static bool CheckPresent()
        {
            return CheckPresent(VID, PID);
        }

        public static USBDevice FindDevice()
        {
            return (USBDevice)FindDevice(VID, PID, typeof(USBDevice));
        }

        protected override void HandleDataReceived(InputReport oInRep)
        {
            if(mButtons != oInRep.Buffer[1])
            {
                mButtons = oInRep.Buffer[1];
                if (OnButtonChanged != null)
                {
                    if(mButtons == 29)
                    {
                        // Fire the event handler if assigned
                        MyInputReport myIn = (MyInputReport)oInRep;
                        OnButtonChanged(this, new ButtonChangedEventArgs(myIn.Buttons));
                    }
                }
            }
        }


        public void SetOutput(bool out1, bool out2, bool out3, bool out4, bool out5, bool out6, bool out7, bool out8)
        {
            MyOutputReport oRep = new MyOutputReport(this);	// create output report
            oRep.SetLightStates(out1, out2, out3, out4, out5, out6, out7, out8);	// set the lights states
            try
            {
                Write(oRep); // write the output report
            }
            catch (HIDDeviceException ex)
            {
                throw new Exception("Disconnected!");
                // Disconnected?
            }
        }

        public class MyInputReport : InputReport
        {
            public ButtonStates Buttons = new ButtonStates();

            public MyInputReport(HIDDevice device) : base(device) {}

            public override void ProcessData()
            {
                byte[] arrData = Buffer;
                Buttons.Inp1 = ((arrData[1] & 0x10) != 0);
                Buttons.Inp2 = ((arrData[1] & 0x20) != 0);
                Buttons.Inp3 = ((arrData[1] & 0x01) != 0);
                Buttons.Inp4 = ((arrData[1] & 0x40) != 0);
                Buttons.Inp5 = ((arrData[1] & 0x80) != 0);
            }
        }

        public class MyOutputReport : OutputReport
        {
		    public MyOutputReport(HIDDevice device) : base(device) {}

            public void SetLightStates(bool out1, bool out2, bool out3, bool out4, bool out5, bool out6, bool out7, bool out8)
            {
                byte[] arrBuff = Buffer;

                arrBuff[0] = 0;// (byte)(out1 ? 0xff : 0);
                arrBuff[2] = (byte)(out2 ? 0xff : 0);
                arrBuff[3] = (byte)(out3 ? 0xff : 0);
                arrBuff[4] = (byte)(out4 ? 0xff : 0);
                arrBuff[5] = (byte)(out5 ? 0xff : 0);
                arrBuff[6] = (byte)(out6 ? 0xff : 0);
                arrBuff[7] = (byte)(out7 ? 0xff : 0);
                arrBuff[8] = (byte)(out8 ? 0xff : 0);
            }
        }

    }
}
