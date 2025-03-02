using System;
using System.IO;
using System.Drawing;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SpriteConverter {
    internal class Program {
        static string InfoMsg = @"
Sprite Converter 2025-02-22

USAGE:
  font <path> [-start=<asciiStartIndex>] [-monospace]
  sprite <path>";

        static void Main(string[] args) {
            if (args.Length < 2) {
                Console.WriteLine(InfoMsg);
                return;
            }

            string cmd = args[0];

            switch(cmd) {
                case "font": ToFont(args); break;
                case "sprite": ToSprite(args); break;
            }
        }

        static int ParseOptionNumber(string str) {
            int index = str.LastIndexOf('=');
            
            if (index + 1 == str.Length) {
                Console.WriteLine($"Error parsing number in option string {str}. (No number after '=').");
                return -1;
            }
            
            string num = str.Substring(index + 1);
        
            if (int.TryParse(num, out int res)) {
                return res;
            }

            Console.WriteLine($"Error parsing number in option string {str}.");

            return -1;
        }

        static void ToFont(string[] args) {
            string path = args[1];
            if (!FileCheck(path)) {
                return;
            }

            int ascii = 0;
            bool mono = false;

            foreach (string arg in args) {
                if (arg.StartsWith("-start=")) {
                    ascii = ParseOptionNumber(arg);
                }

                if (arg == "-monospace") {
                    mono = true;
                }
            }

            StringBuilder output = new StringBuilder();

            ByteImage img = new ByteImage(new Bitmap(path));

            int charW = FontFindCharWidth(img);
            int charH = FontFindCharHeight(img);

            if (img.Width % charW != 0) {
                Console.WriteLine($"Error: Character width {charW} doesn't evenly fit into image width {img.Width}.");
                return;
            }

            if (img.Height % (charH + 1) != 0) {
                Console.WriteLine($"Error: Character height {charH + 1} doesn't evenly fit into image height {img.Height}.");
                return;
            }

            int W = img.Width / charW;
            int H = img.Height / charH;

            StringBuilder table = new StringBuilder();
            table.AppendLine("FONT_TABLE:");

            for (int y = 0; y < H; y++) {
                for (int x = 0; x < W; x++) {
                    table.AppendLine($"    dl FONT_CHAR_{ascii}");
                    ByteImage character = img.GetSubImage(x * charW, y * (charH + 1), charW, charH + 1);
                    FontParseCharacter(character, output, ascii);
                    ascii++;
                }
            }

            table.AppendLine();

            Console.WriteLine(table.ToString());
            Console.WriteLine(output.ToString());

            File.WriteAllText("output.txt", table.ToString() + output.ToString());
        }

        static void FontParseCharacter(ByteImage img, StringBuilder str, int ascii) {
            string name = $"FONT_CHAR_{ascii}: ;{((ascii >= ' ' && ascii < 127) ? ((char)ascii).ToString() : ascii.ToString())}";
            str.AppendLine(name);

            int offsetX = int.MaxValue;
            int offsetY = int.MaxValue;
            int maxX = int.MinValue;
            int maxY = int.MinValue;

            //find image bounds
            for (int x = 0; x < img.Width; x++) {
                for (int y = 1; y < img.Height; y++) {
                    if (img.Get(x, y) == Black) {
                        if (x < offsetX) {
                            offsetX = x;
                        }

                        if (y - 1 < offsetY) {
                            offsetY = y - 1;
                        }

                        if (x > maxX) {
                            maxX = x;
                        }

                        if (y - 1 > maxY) {
                            maxY = y - 1;
                        }
                    }
                }
            }

            int width = maxX - offsetX + 1;
            int height = maxY - offsetY + 1;

            bool noImgData = offsetX == int.MaxValue;

            int widthMarker = 0;
            for (int x = img.Width - 1; x >= 0; x--) {
                if (IsWidthLimiter(img.Get(x, 0))) {
                    widthMarker = x + 1;
                    break;
                }
            }

            if (noImgData) {
                offsetX = 0;
                offsetY = 0;
                height = 0;
                width = widthMarker;
            }

            ulong[] image = new ulong[height];

            if (!noImgData) {
                width = Math.Max(width, widthMarker);

                for (int y = 0; y < height; y++) {
                    for (int x = 0; x < width; x++) {
                        uint color = img.Get(x + offsetX, y + offsetY + 1);
                        if (color == Black) {
                            image[y] |= 1ul << (63 - x);
                        }
                    }
                }
            }

            if (IsDownOne(img.Get(0, 0))) {
                offsetY++;
            }

            str.AppendLine($"    db ${width.ToString("X2")}, ${height.ToString("X2")}");

            int offset = offsetY * 320 + offsetX;
            str.AppendLine($"    db ${offsetX.ToString("X2")}, ${offsetY.ToString("X2")}, ${(offset & 0xFF).ToString("X2")}, ${((offset >> 8) & 0xFF).ToString("X2")}, $00");

            int bytesPerLine = width / 8;

            if (width % 8 != 0) {
                bytesPerLine++;
            } 

            if (height > 0) {
                str.Append("    db ");
            }

            for (int i = 0; i < height; i++) {
                ulong data = image[i];

                for (int j = 0; j < bytesPerLine; j++) {
                    int dataByte = (int)((data >> ((7 - j) * 8)) & 0xFF);
                    str.Append($"${dataByte.ToString("X2")}, ");
                }
            }

            str.Remove(str.Length - 2, 2);

            str.AppendLine();
            str.AppendLine();
        }

        static int FontFindCharWidth(ByteImage img) {
            int w = 0;

            bool firstRed = false;

            for (int x = 0; x < img.Width; x++) {
                uint color = img.Get(x, 0);
                
                if (IsDownOne(color)) {
                    continue;
                }

                w = x + 1;
                firstRed = IsMarkerRed(color);
                break;
            }

            for (int x = w; x < img.Width; x++) {
                uint color = img.Get(x, 0);

                if (x > 0 && ((firstRed && IsMarkerGreen(color)) || (!firstRed && IsMarkerRed(color)))) {
                    break;
                }

                if (IsMarker(color)) {
                    w++;
                } else {
                    break;
                }
            }

            return w;
        }

        static int FontFindCharHeight(ByteImage img) {
            int h = 0;

            for (int y = 1; y < img.Height; y++) {
                if (IsMarker(img.Get(0, y))) {
                    break;
                }

                h++;
            }

            return h;
        }

        static uint Red = ByteImage.ArgbToU32(255, 63, 63);
        static uint DarkRed = ByteImage.ArgbToU32(191, 63, 63);
        static uint Green = ByteImage.ArgbToU32(63, 255, 63);
        static uint DarkGreen = ByteImage.ArgbToU32(63, 191, 63);
        static uint DownOne = ByteImage.ArgbToU32(255, 63, 255);

        static uint White = ByteImage.ArgbToU32(255, 255, 255);
        static uint Black = ByteImage.ArgbToU32(0, 0, 0);

        static uint[] Markers = { Red, DarkRed, Green, DarkGreen, DownOne};

        static bool IsMarker(uint color) => Array.IndexOf(Markers, color) != -1;
        static bool IsMarkerRed(uint color) => color == Red || color == DarkRed;
        static bool IsMarkerGreen(uint color) => color == Green || color == DarkGreen;
        static bool IsWidthLimiter(uint color) => color == DarkRed || color == DarkGreen;
        static bool IsDownOne(uint color) => color == DownOne;

        static void ToSprite(string[] args) {
            string path = args[1];
            if (!FileCheck(path)) {
                return;
            }

            ByteImage img = new ByteImage(new Bitmap(path));
        }

        static bool FileCheck(string path) {
            if (!File.Exists(path)) {
                Console.WriteLine($"File at path {path} doesn't exist.");
                return false;
            }

            return true;
        }
    }
}
