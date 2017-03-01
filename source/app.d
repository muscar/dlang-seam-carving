import std.algorithm.comparison;
import std.stdio;
import std.math;
import std.typecons;

import arsd.png;

auto sobelX = [[-1, 0, 1],
               [-2, 0, 2],
               [-1, 0, 1]];
 
auto sobelY = [[-1, -2, -1],
               [ 0,  0,  0],
               [ 1,  2,  1]];

auto at(MemoryImage img, int x, int y)
{
    return img.getPixel(x, y).toBW.r;
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

auto filter3x3(S)(MemoryImage image, int[][] kernel, S s)
{
    auto res = new TrueColorImage(image.width, image.height);
    foreach (x; 1..image.width - 1) {
        foreach (y; 1..image.height - 1) {
            int[3] acc = [0, 0, 0];
            foreach (ky; 0..3) {
                foreach (kx; 0..3) {
                    import std.format;
                    auto p = image.getPixel(x + kx - 1, y + ky - 1);
                    auto k = kernel[ky][kx];
                    acc[0] += (p.r * k);
                    acc[1] += (p.g * k);
                    acc[2] += (p.b * k);
                }
            }
            res.setPixel(x, y, Color(s(acc[0]), s(acc[1]), s(acc[2])));
        }
    }
    return res;
}

auto gradients(MemoryImage image, int[][] hKernel, int[][] vKernel)
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
            px = clamp(px, 0, 255);
            py = clamp(py, 0, 255);
            auto val = cast(int)clamp(sqrt(cast(float)(px * px) + cast(float)(py * py)).ceil, 0, 255);
            edge.setPixel(x, y, Color(val, val, val).toBW);
        }
    }
    return edge;
}

void main(string[] args)
{
    auto img = readPng(args[1]);
    auto channels = decompose(img);
    auto redge = sobel(channels.red);
    auto gedge = sobel(channels.green);
    auto bedge = sobel(channels.blue);

    auto redge1 = gradients(channels.red, sobelX, sobelY);
    auto gedge1 = gradients(channels.green, sobelX, sobelY);
    auto bedge1 = gradients(channels.blue, sobelX, sobelY);

    auto bwImg = new TrueColorImage(img.width, img.height);
    foreach (x; 0..img.width) {
        foreach (y; 0..img.height) {
            bwImg.setPixel(x, y, img.getPixel(x, y).toBW);
        }
    }
    auto imgEdge = sobel(bwImg);

    auto edge = new TrueColorImage(img.width, img.height);
    foreach (x; 0..img.width) {
        foreach (y; 0..img.height) {
            auto val = clamp(redge.at(x, y) + gedge.at(x, y) + bedge.at(x, y), 0, 255);
            edge.setPixel(x, y, Color(val, val, val).toBW);
        }
    }

    writePng("out/r.png", channels.red);
    writePng("out/g.png", channels.green);
    writePng("out/b.png", channels.blue);

    writePng("out/redge.png", redge);
    writePng("out/gedge.png", gedge);
    writePng("out/bedge.png", bedge);

    writePng("out/redge1.png", redge1);
    writePng("out/gedge1.png", gedge1);
    writePng("out/bedge1.png", bedge1);

    writePng("out/edge.png", edge);
    writePng("out/img_edge.png", imgEdge);
}
