import std.stdio;
import std.math;

import arsd.png;

auto sobelX = [[-1, 0, 1],
               [-2, 0, 2],
               [-1, 0, 1]];
 
auto sobelY = [[-1,-2, -1],
               [ 0, 0,  0],
               [ 1, 2,  1]];

auto at(MemoryImage img, int x, int y)
{
    auto p = img.getPixel(x, y);
    assert(p.r == p.g && p.g == p.b);
    return p.r;
}

auto sobel(MemoryImage img)
{
    auto edge = new TrueColorImage(img.width, img.height);
    foreach (int x; 1..img.width - 1) {
        foreach (int y; 1..img.height - 1) {
            auto px = (sobelX[0][0] * img.at(x - 1, y - 1)) + (sobelX[0][1] * img.at(x, y - 1)) + (sobelX[0][2] * img.at(x + 1, y - 1)) +
                      (sobelX[1][0] * img.at(x - 1, y))   + (sobelX[1][1] * img.at(x, y))   + (sobelX[1][2] * img.at(x + 1, y)) +
                      (sobelX[2][0] * img.at(x - 1, y + 1)) + (sobelX[2][1] * img.at(x, y + 1)) + (sobelX[2][2] * img.at(x + 1, y + 1));
            auto py = (sobelY[0][0] * img.at(x - 1, y - 1)) + (sobelY[0][1] * img.at(x, y - 1)) + (sobelY[0][2] * img.at(x + 1, y - 1)) +
                      (sobelY[1][0] * img.at(x - 1, y))   + (sobelY[1][1] * img.at(x, y))   + (sobelY[1][2] * img.at(x + 1, y)) +
                      (sobelY[2][0] * img.at(x - 1, y + 1)) + (sobelY[2][1] * img.at(x, y + 1)) + (sobelY[2][2] * img.at(x + 1, y + 1));
            auto val = cast(int)(sqrt(cast(float)(px * px) + cast(float)(py * py)).ceil);
            edge.setPixel(x, y, Color(val, val, val));
        }
    }
    return edge;
}

void main(string[] args)
{
    auto img = readPng(args[1]);
    auto rimg = new TrueColorImage(img.width, img.height);
    auto gimg = new TrueColorImage(img.width, img.height);
    auto bimg = new TrueColorImage(img.width, img.height);

    foreach (int x; 0..img.width) {
        foreach (int y; 0..img.height) {
            auto c = img.getPixel(x, y);
            rimg.setPixel(x, y, Color(c.r, c.r, c.r));
            gimg.setPixel(x, y, Color(c.g, c.g, c.g));
            bimg.setPixel(x, y, Color(c.b, c.b, c.b));
        }
    }

    auto redge = sobel(rimg);
    auto gedge = sobel(gimg);
    auto bedge = sobel(bimg);

    writePng("r.png", rimg);
    writePng("g.png", gimg);
    writePng("b.png", bimg);

    writePng("redge.png", redge);
    writePng("gedge.png", gedge);
    writePng("bedge.png", bedge);
}
