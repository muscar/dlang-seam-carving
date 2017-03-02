import std.algorithm.comparison;
import std.conv;
import std.math;
import std.stdio;
import std.typecons;

import arsd.png;

immutable auto sobelX = [[-1, 0, 1],
                         [-2, 0, 2],
                         [-1, 0, 1]];
 
immutable auto sobelY = [[-1, -2, -1],
                         [ 0,  0,  0],
                         [ 1,  2,  1]];

auto at(MemoryImage img, int x, int y)
{
    return img.getPixel(x, y).components[0];
}

auto decompose(MemoryImage img)
{
    auto rimg = new TrueColorImage(img.width, img.height);
    auto gimg = new TrueColorImage(img.width, img.height);
    auto bimg = new TrueColorImage(img.width, img.height);

    foreach (x; 0..img.width) {
        foreach (y; 0..img.height) {
            auto c = img.getPixel(x, y);
            rimg.setPixel(x, y, Color(c.r, c.r, c.r).toBW);
            gimg.setPixel(x, y, Color(c.g, c.g, c.g).toBW);
            bimg.setPixel(x, y, Color(c.b, c.b, c.b).toBW);
        }
    }

    return tuple!("red", "green", "blue")(rimg, gimg, bimg);
}

auto filter3x3(S)(MemoryImage image, immutable int[][] kernel, S s)
{
    auto res = new TrueColorImage(image.width, image.height);
    foreach (x; 1..image.width - 1) {
        foreach (y; 1..image.height - 1) {
            int[4] acc = [0, 0, 0, 255];
            foreach (ky; 0..3) {
                foreach (kx; 0..3) {
                    accumulate(acc, image.getPixel(x + kx - 1, y + ky - 1).components, kernel[ky][kx]);
                }
            }
            foreach (ref c; acc) {
                c = s(c);
            }
            res.setPixel(x, y, Color.fromComponents(acc.to!(ubyte[4])));
        }
    }
    return res;
}

auto accumulate(ref int[4] acc, immutable ubyte[4] c, int k)
{
    acc[0] += c[0] * k;
    acc[1] += c[1] * k;
    acc[2] += c[2] * k;
}

auto gradients(MemoryImage image, immutable int[][] hKernel, immutable int[][] vKernel)
{
    auto res = new TrueColorImage(image.width, image.height);
    auto hGrad = filter3x3(image, hKernel, (int v) => clamp(v, 0, 255));
    auto vGrad = filter3x3(image, vKernel, (int v) => clamp(v, 0, 255));
    foreach (x; 0..image.width) {
        foreach (y; 0..image.height) {
            float h = hGrad.getPixel(x, y).r;
            float v = vGrad.getPixel(x, y).r;
            auto m = clamp(cast(int)(sqrt(h.pow(2) + v.pow(2)).ceil), 0, 255);
            res.setPixel(x, y, Color(m, m, m));
        }
    }
    return res;
}

auto sobelGradients(MemoryImage image)
{
    return gradients(image, sobelX, sobelY);
}

auto combine(MemoryImage redge, MemoryImage gedge, MemoryImage bedge)
{
    assert(redge.width == bedge.width && bedge.width == gedge.width);
    assert(redge.width == bedge.width && bedge.width == gedge.width);

    auto edge = new TrueColorImage(redge.width, redge.height);
    foreach (x; 0..redge.width) {
        foreach (y; 0..redge.height) {
            auto val = clamp(redge.at(x, y) + gedge.at(x, y) + bedge.at(x, y), 0, 255);
            edge.setPixel(x, y, Color(val, val, val));
        }
    }
    return edge;
}

void main(string[] args)
{
    auto img = readPng(args[1]);
    auto channels = img.decompose;

    auto redge = channels.red.sobelGradients;
    auto gedge = channels.green.sobelGradients;
    auto bedge = channels.blue.sobelGradients;
    auto edge = combine(redge, gedge, bedge);

    writePng("out/r.png", channels.red);
    writePng("out/g.png", channels.green);
    writePng("out/b.png", channels.blue);

    writePng("out/redge.png", redge);
    writePng("out/gedge.png", gedge);
    writePng("out/bedge.png", bedge);

    writePng("out/edge.png", edge);
}
