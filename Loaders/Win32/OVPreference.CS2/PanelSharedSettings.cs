using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Text;
using System.Windows.Forms;

namespace OVPreference.CS2
{
    public partial class PanelSharedSettings : UserControl
    {
        public PanelSharedSettings()
        {
            InitializeComponent();
            
            //FontComboBox fontComboBox1;
            fontComboBox1.Populate(false);
            fontColorPicker.Items = new KnownColorCollection(KnownColorFilter.All);
            bgColorPicker.Items = new KnownColorCollection(KnownColorFilter.All);
            //fontComboBox1.Populate(false);
        }

        private void button1_Click(object sender, EventArgs e)
        {
            this.colorDialog1.ShowDialog();
        }

        private void fontColorPickerNotiFunction(object sender, EventArgs e)
        {
            if(fontColorPicker.SelectedIndex.Equals(168))
            {
                this.colorDialog1.ShowDialog();
            }
        }
        private void bgColorPickerNotiFunction(object sender, EventArgs e)
        {
            if (fontColorPicker.SelectedIndex.Equals(168))
            {
                this.colorDialog1.ShowDialog();
            }
        }
    }


}