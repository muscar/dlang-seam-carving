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
    foreach (x; 1..img.width - 1) {
        foreach (y; 1..img.height - 1) {
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

    foreach (x; 0..img.width) {
        foreach (y; 0..img.height) {
            auto c = img.getPixel(x, y);
            rimg.setPixel(x, y, Color(c.r, c.r, c.r));
            gimg.setPixel(x, y, Color(c.g, c.g, c.g));
            bimg.setPixel(x, y, Color(c.b, c.b, c.b));
        }
    }

    auto redge = sobel(rimg);
    auto gedge = sobel(gimg);
    auto bedge = sobel(bimg);

    auto edge = new TrueColorImage(img.width, img.height);
    foreach (x; 0..img.width) {
        foreach (y; 0..img.height) {
            auto val = redge.getPixel(x, y).r + gedge.getPixel(x, y).g + bedge.getPixel(x, y).b;
            edge.setPixel(x, y, Color(val, val, val));
        }
    }

    writePng("out/r.png", rimg);
    writePng("out/g.png", gimg);
    writePng("out/b.png", bimg);

    writePng("out/redge.png", redge);
    writePng("out/gedge.png", gedge);
    writePng("out/bedge.png", bedge);

    writePng("out/edge.png", edge);
}
