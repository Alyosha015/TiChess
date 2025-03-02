using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

namespace SpriteConverter {
    internal class ByteImage {
        public int Width { get; set; }
        public int Height { get; set; }
        public byte[] Data { get; set; }

        public ByteImage(int width, int height) {
            Width = width;
            Height = height;
            Data = new byte[Width * Height * 4];
        }

        public ByteImage(Bitmap image) {
            Width = image.Width;
            Height = image.Height;

            Data = new byte[Width * Height * 4];

            BitmapData bitmapData = image.LockBits(new Rectangle(0, 0, Width, Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            IntPtr ptr = bitmapData.Scan0;

            Marshal.Copy(ptr, Data, 0, Data.Length);

            image.UnlockBits(bitmapData);
        }

        public Bitmap ToBitmap() {
            Bitmap image = new Bitmap(Width, Height);

            BitmapData bitmapData = image.LockBits(new Rectangle(0, 0, Width, Height), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            IntPtr ptr = bitmapData.Scan0;
            Marshal.Copy(Data, 0, ptr, Data.Length);

            image.UnlockBits(bitmapData);

            return image;
        }

        public ByteImage GetSubImage(int x, int y, int width, int height) {
            ByteImage subImg = new ByteImage(width, height);

            for (int Y = 0; Y < height; Y++) {
                for (int X = 0; X < width; X++) {
                    subImg.Set(X, Y, Get(x + X, y + Y));
                }
            }

            return subImg;
        }

        public ByteImage GetCopy() {
            ByteImage image = new ByteImage(Width, Height);

            for (int i = 0; i < Data.Length; i++) {
                image.Data[i] = Data[i];
            }

            return image;
        }

        public uint Get(int x, int y) {
            uint output = (uint)GetA(x, y) << 24;
            output += (uint)GetR(x, y) << 16;
            output += (uint)GetG(x, y) << 8;
            output += GetB(x, y);
            return output;
        }

        public void Set(int x, int y, uint argb) {
            SetA(x, y, (byte)(argb >> 24));
            SetR(x, y, (byte)(argb >> 16));
            SetG(x, y, (byte)(argb >> 8));
            SetB(x, y, (byte)argb);
        }

        public void SetBlock(int x, int y, int w, int h, uint argb) {
            for (int yy = 0; yy < h; yy++) {
                for (int xx = 0; xx < w; xx++) {
                    Set(x + xx, y + yy, argb);
                }
            }
        }

        public byte GetR(int x, int y) => Data[(y * Width + x) * 4 + 2];
        public byte GetG(int x, int y) => Data[(y * Width + x) * 4 + 1];
        public byte GetB(int x, int y) => Data[(y * Width + x) * 4];
        public byte GetA(int x, int y) => Data[(y * Width + x) * 4 + 3];

        public void SetR(int x, int y, byte r) {
            Data[(y * Width + x) * 4 + 2] = r;
        }

        public void SetG(int x, int y, byte g) {
            Data[(y * Width + x) * 4 + 1] = g;
        }

        public void SetB(int x, int y, byte b) {
            Data[(y * Width + x) * 4] = b;
        }

        public void SetA(int x, int y, byte a) {
            Data[(y * Width + x) * 4 + 3] = a;
        }

        public static uint ArgbToU32(byte r, byte g, byte b, byte a = 255) => (uint)(a << 24) + (uint)(r << 16) + (uint)(g << 8) + b;
    }
}
