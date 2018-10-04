using iMobileDevice;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Drawing;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Windows.Forms;
using iMobileDevice.iDevice;
using iMobileDevice.Lockdown;
using Newtonsoft.Json.Linq;


namespace blob_saver {
    public partial class Form1 : Form {
        private ILockdownApi lockdown = LibiMobileDevice.Instance.Lockdown;
        private static readonly HttpClient client = new HttpClient();

        public Form1() {
            InitializeComponent();
            NativeLibraries.Load();
            Refresh();
        }

        private List<string> devices = new List<string>();

        private void Refresh() {
            comboBox1.Items.Clear();

            ReadOnlyCollection<string> udids;
            int count = 0;

            var idevice = LibiMobileDevice.Instance.iDevice;

            var ret = idevice.idevice_get_device_list(out udids, ref count);

            if (ret == iDeviceError.NoDevice) {
                // Not actually an error in our case
                return;
            }

            ret.ThrowOnError();
            // Get the device name
            foreach (var udid in udids) {
                iDeviceHandle deviceHandle;
                idevice.idevice_new(out deviceHandle, udid).ThrowOnError();

                LockdownClientHandle lockdownHandle;
                lockdown.lockdownd_client_new_with_handshake(deviceHandle, out lockdownHandle, null)
                    .ThrowOnError();

                string deviceName;
                lockdown.lockdownd_get_device_name(lockdownHandle, out deviceName).ThrowOnError();
                comboBox1.Items.Add(deviceName + " " + udid);
                deviceHandle.Dispose();
                lockdownHandle.Dispose();
            }

            if (comboBox1.Items.Count != 0) {
                comboBox1.SelectedIndex = 0;
            }
        }
        private async void button1_Click(object sender, EventArgs e) {
            richTextBox1.ForeColor = Color.Black;
            string output = "";
            Process proc = new Process {
                StartInfo = new ProcessStartInfo {
                    FileName = @".\bin\ideviceinfo.exe",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    CreateNoWindow = true
                }
            };
            proc.Start();
            while (!proc.StandardOutput.EndOfStream) {
                output += proc.StandardOutput.ReadLine() + "\n";
            }

            string uniqueChipID = Regex.Match(output, "(?<=UniqueChipID: ).*").Value;
            string hardwareModel = Regex.Match(output, "(?<=HardwareModel: ).*").Value;
            string productType = Regex.Match(output, "(?<=ProductType: ).*").Value;
            if (uniqueChipID == "" || hardwareModel == "" || productType == "") {
                MessageBox.Show("Please connect your device.");
                return;
            }
            Dictionary<string, string> formDictionary = new Dictionary<string, string> {
                {"ecid", uniqueChipID},
                {"boardConfig", hardwareModel},
                {"deviceID", productType}
            };
            FormUrlEncodedContent content = new FormUrlEncodedContent(formDictionary);
            HttpResponseMessage response = await client.PostAsync("https://tsssaver.1conan.com/app.php", content);
            string responseString = await response.Content.ReadAsStringAsync();
            JObject parsedResponse = JObject.Parse(responseString);
            if ((bool) parsedResponse["success"]) {
                richTextBox1.Text = (string) parsedResponse["url"];
                Process.Start(richTextBox1.Text == "" ? " " : richTextBox1.Text);
            } else if (!((bool) parsedResponse["success"]) && parsedResponse["error"] != null ) {
                richTextBox1.Text = (string)parsedResponse["error"]["message"];
                richTextBox1.ForeColor = Color.Red;
            } else {
                richTextBox1.Text = "Failed";
                richTextBox1.ForeColor = Color.Red;
            }
        }

        private void button2_Click(object sender, EventArgs e) {
            Refresh();
        }

        private void button3_Click(object sender, EventArgs e) {
            Clipboard.SetText(richTextBox1.Text == "" ? " " : richTextBox1.Text);
        }

        private void richTextBox1_LinkClicked(object sender, LinkClickedEventArgs e) {
            Process.Start(e.LinkText);
        }
    }
}
