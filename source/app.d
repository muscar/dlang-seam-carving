import std.algorithm.comparison;
import std.conv;
import std.format;
import std.math;
import std.stdio;
import std.traits;
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

template Convolve(alias acc, alias image, int[][] kernel, alias imgX, alias imgY, int x = 0, int y = 0)
{
    static if (y < kernel.length) {
        immutable auto k = kernel[y][x];
        immutable auto accumulateCall = k != 0 ? "accumulate(%s, %s.getPixel(%s + %d, %s + %d).components, %d);\n".format(acc.stringof, image.stringof, imgX.stringof, x - 1, imgY.stringof, y - 1, k) : "";
        static if (x < kernel[0].length - 1) {
            const Convolve = accumulateCall ~ Convolve!(acc, image, kernel, imgX, imgY, x + 1, y);
        } else {
            const Convolve = accumulateCall ~ Convolve!(acc, image, kernel, imgX, imgY, 0, y + 1);
        }
    } else {
        const Convolve = "";
    }
}

auto filter(int[][] K, S)(MemoryImage image, S s)
{
    auto res = new TrueColorImage(image.width, image.height);
    foreach (x; 1..image.width - 1) {
        foreach (y; 1..image.height - 1) {
            int[4] acc = [0, 0, 0, 0];
            mixin(Convolve!(acc, image, K, x, y));
            foreach (ref c; acc) {
                c = s(c);
            }
            res.setPixel(x, y, Color(acc[0], acc[1], acc[2]));
        }
    }
    return res;
}

auto accumulate(ref int[4] acc, immutable ubyte[4] c, int k) pure @nogc
{
    acc[] += c[] * k;
}

auto gradients(int[][] K1, int[][] K2)(MemoryImage image)
{
    auto res = new TrueColorImage(image.width, image.height);
    auto hGrad = filter!K1(image, (int v) => clamp(v, 0, 255));
    auto vGrad = filter!K2(image, (int v) => clamp(v, 0, 255));
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
    return gradients!(sobelX, sobelY)(image);
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
    int acc, image, x, y;
    writeln(Convolve!(acc, image, sobelX, x, y));
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
