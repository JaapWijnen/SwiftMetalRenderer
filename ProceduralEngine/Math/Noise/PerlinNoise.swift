import simd

class PerlinNoise {

    private static let permutations: [Int] = [
        151,160,137,91,90,15,
        131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
        190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
        88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
        77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
        102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
        135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
        5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
        223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
        129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
        251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
        49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
        138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
        151,160,137,91,90,15,
        131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
        190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
        88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
        77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
        102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
        135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
        5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
        223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
        129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
        251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
        49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
        138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
    ]

    private static let gradients: [double3] = [
        double3(1,1,0), double3(-1,1,0), double3(1,-1,0), double3(-1,-1,0),
        double3(1,0,1), double3(-1,0,1), double3(1,0,-1), double3(-1,0,-1),
        double3(0,1,1), double3(0,-1,1), double3(0,1,-1), double3(0,-1,-1),
        double3(1,1,0), double3(-1,1,0), double3(0,-1,1), double3(0,-1,-1)
    ]

    @inline(__always)
    private static func fade(_ t: Double) -> Double {
        return t * t * t * (t * (t * 6 - 15) + 10)
    }

    @inline(__always)
    private static func dfade(_ t: Double, _ tp: double3) -> double3 {
        return 30 * t * t * (t - 1) * (t - 1) * tp
    }

    @inline(__always)
    private static func lerp(_ t: Double, _ a: Double, _ b: Double) -> Double {
        return a + t * (b - a)
    }

    @inline(__always)
    private static func dlerp(_ t: Double, _ a: Double, _ b: Double, _ tp: double3, _ ap: double3, _ bp: double3) -> double3 {
        return (1 - t) * ap + t * bp + (b - a) * tp
    }

    @inline(__always)
    private static func grad1(hash: Int, x: Double) -> Double {
        let h = hash & 15
        var grad = 1.0 + Double(h & 7)   // Gradient value 1.0, 2.0, ..., 8.0
        if h & 8 == 0 { grad = -grad }  // and a random sign for the gradient
        return grad * x                 // Multiply the gradient with the distance
    }

    @inline(__always)
    private static func grad2(hash: Int, x: Double, y: Double) -> Double {
        let h = hash & 7        // Convert low 3 bits of hash code
        let u = h < 4 ? x : y   // into 8 simple gradient directions,
        let v = h < 4 ? y : x   // and compute the dot product with (x,y).
        return ((h & 1) == 0 ? -u : u) + ((h & 2) == 0 ? -2.0 * v : 2.0 * v)
    }

    /*@inline(__always)
    private static func grad3(hash: Int, x: Double, y: Double, z: Double) -> Double {
        let h = hash & 15                               // Convert low 4 bits of hash code into 12 simple
        let u = h < 8 ? x : y                           // gradient directions, and compute dot product.
        let v = h < 4 ? y : h == 12 || h == 14 ? x : z  // Fix repeats at h = 12 to 15
        return (h & 1 == 0 ? u : -u) + (h & 2 == 0 ? v : -v)
    }*/

    @inline(__always)
    private static func grad4(hash: Int, x: Double, y: Double, z: Double, t: Double) -> Double {
        let h = hash & 31           // Convert low 5 bits of hash code into 32 simple
        let u = h < 24 ? x : y      // gradient directions, and compute dot product.
        let v = h < 16 ? y : z
        let w = h < 8 ? z : t
        return (h & 1 == 0 ? -u : u) + (h & 2 == 0 ? -v : v) + (h & 4 == 0 ? -w : w)
    }

    private static func fastFloor(_ x: Double) -> Int {
        let xi = Int(x)
        return x < Double(xi) ? xi - 1 : xi
    }

    static func noise(x: Double) -> Double {
        var ix0: Int = fastFloor(x)     // Integer part of x
        let fx0: Double = x - Double(ix0) // Fractional part of x
        let ix1: Int = (ix0 + 1) & 0xff
        let fx1: Double = fx0 - 1.0
        ix0 = ix0 & 0xff                // wrap to 0...255

        let s: Double = fade(fx0)
        let n0: Double = grad1(hash: permutations[ix0], x: fx0)
        let n1: Double = grad1(hash: permutations[ix1], x: fx1)

        return 0.188 * lerp(s, n0, n1)
    }

    static func periodicNoise(x: Double, px: Int) -> Double {
        var ix0: Int = fastFloor(x)            // Integer part of x
        let fx0: Double = x - Double(ix0)         // Fractional part of x
        let ix1: Int = ((ix0 + 1) % px) & 0xff  // Wrap to 0..px-1 *and* wrap to 0..255
        ix0 = (ix0 % px) & 0xff                 // (because px might be greater than 256)
        let fx1: Double = fx0 - 1.0

        let s: Double = fade(fx0)
        let n0: Double = grad1(hash: permutations[ix0], x: fx0)
        let n1: Double = grad1(hash: permutations[ix1], x: fx1)

        return 0.188 * lerp(s, n0, n1)
    }

    static func noise(x: Double, y: Double) -> Double {
        var ix0 = fastFloor(x)     // Integer part of x
        var iy0 = fastFloor(y)     // Integer part of y
        let fx0 = x - Double(ix0)    // Fractional part of x
        let fy0 = y - Double(iy0)    // Fractional part of y

        let fx1 = fx0 - 1.0
        let fy1 = fy0 - 1.0
        let ix1 = (ix0 + 1) & 0xff  // Wrap to 0...255
        let iy1 = (iy0 + 1) & 0xff  // Wrap to 0...255

        ix0 = ix0 & 0xff
        iy0 = iy0 & 0xff

        let t = fade(fy0)
        let s = fade(fx0)

        var nx0 = grad2(hash: permutations[ix0 + permutations[iy0]], x: fx0, y: fy0)
        var nx1 = grad2(hash: permutations[ix0 + permutations[iy1]], x: fx0, y: fy1)
        let n0 = lerp(t, nx0, nx1)

        nx0 = grad2(hash: permutations[ix1 + permutations[iy0]], x: fx1, y: fy0)
        nx1 = grad2(hash: permutations[ix1 + permutations[iy1]], x: fx1, y: fy1)
        let n1 = lerp(t, nx0, nx1)

        return 0.507 * lerp(s, n0, n1)
    }

    static func periodicNoise(x: Double, y: Double, px: Int, py: Int) -> Double {
        var ix0 = fastFloor(x)     // Integer part of x
        var iy0 = fastFloor(y)     // Integer part of y
        let fx0 = x - Double(ix0)    // Fractional part of x
        let fy0 = y - Double(iy0)    // Fractional part of y

        let fx1 = fx0 - 1.0
        let fy1 = fy0 - 1.0
        let ix1 = ((ix0 + 1) % px) & 0xff  // Wrap to 0...255
        let iy1 = ((iy0 + 1) % py) & 0xff

        ix0 = (ix0 % px) & 0xff
        iy0 = (iy0 % py) & 0xff

        let t = fade(fy0)
        let s = fade(fx0)

        var nx0 = grad2(hash: permutations[ix0 + permutations[iy0]], x: fx0, y: fy0)
        var nx1 = grad2(hash: permutations[ix0 + permutations[iy1]], x: fx0, y: fy1)
        let n0 = lerp(t, nx0, nx1)

        nx0 = grad2(hash: permutations[ix1 + permutations[iy0]], x: fx1, y: fy0)
        nx1 = grad2(hash: permutations[ix1 + permutations[iy1]], x: fx1, y: fy1)
        let n1 = lerp(t, nx0, nx1)

        return 0.507 * lerp(s, n0, n1)
    }

    static func noise(_ vec: float3) -> Double {
        return noise(x: Double(vec.x), y: Double(vec.y), z: Double(vec.z))
    }

    static func noise(x: Double, y: Double, z: Double) -> Double {
        var ix0 = fastFloor(x)     // Integer part of x
        var iy0 = fastFloor(y)     // Integer part of y
        var iz0 = fastFloor(z)     // Integer part of z
        let fx0 = x - Double(ix0)    // Fractional part of x
        let fy0 = y - Double(iy0)    // Fractional part of y
        let fz0 = z - Double(iz0)    // Fractional part of z

        let fx1 = fx0 - 1.0
        let fy1 = fy0 - 1.0
        let fz1 = fz0 - 1.0
        let ix1 = (ix0 + 1) & 0xff  // Wrap to 0...255
        let iy1 = (iy0 + 1) & 0xff
        let iz1 = (iz0 + 1) & 0xff
        ix0 = ix0 & 0xff
        iy0 = iy0 & 0xff
        iz0 = iz0 & 0xff

        let r = fade(fz0)
        let t = fade(fy0)
        let s = fade(fx0)

        let g000 = gradients[permutations[ix0 + permutations[iy0 + permutations[iz0]]] & 15]
        let p000 = double3(fx0, fy0, fz0)
        let n000 = dot(g000, p000)

        let g001 = gradients[permutations[ix0 + permutations[iy0 + permutations[iz1]]] & 15]
        let p001 = double3(fx0, fy0, fz1)
        let n001 = dot(g001, p001)

        let n00z = lerp(r, n000, n001)

        let g010 = gradients[permutations[ix0 + permutations[iy1 + permutations[iz0]]] & 15]
        let p010 = double3(fx0, fy1, fz0)
        let n010 = dot(g010, p010)

        let g011 = gradients[permutations[ix0 + permutations[iy1 + permutations[iz1]]] & 15]
        let p011 = double3(fx0, fy1, fz1)
        let n011 = dot(g011, p011)

        let n01z = lerp(r, n010, n011)

        let n0yz = lerp(t, n00z, n01z)

        let g100 = gradients[permutations[ix1 + permutations[iy0 + permutations[iz0]]] & 15]
        let p100 = double3(fx1, fy0, fz0)
        let n100 = dot(g100, p100)

        let g101 = gradients[permutations[ix1 + permutations[iy0 + permutations[iz1]]] & 15]
        let p101 = double3(fx1, fy0, fz1)
        let n101 = dot(g101, p101)

        let n10z = lerp(r, n100, n101)

        let g110 = gradients[permutations[ix1 + permutations[iy1 + permutations[iz0]]] & 15]
        let p110 = double3(fx1, fy1, fz0)
        let n110 = dot(g110, p110)

        let g111 = gradients[permutations[ix1 + permutations[iy1 + permutations[iz1]]] & 15]
        let p111 = double3(fx1, fy1, fz1)
        let n111 = dot(g111, p111)

        let n11z = lerp(r, n110, n111)

        let n1yz = lerp(t, n10z, n11z)

        return 0.936 * lerp(s, n0yz, n1yz)
    }

    /*static func periodicNoise(x: Double, y: Double, z: Double, px: Int, py: Int, pz: Int) -> Double {
        var ix0 = fastFloor(x)     // Integer part of x
        var iy0 = fastFloor(y)     // Integer part of y
        var iz0 = fastFloor(z)     // Integer part of z
        let fx0 = x - Double(ix0)    // Fractional part of x
        let fy0 = y - Double(iy0)    // Fractional part of y
        let fz0 = z - Double(iz0)    // Fractional part of z

        let fx1 = fx0 - 1.0
        let fy1 = fy0 - 1.0
        let fz1 = fz0 - 1.0
        let ix1 = ((ix0 + 1) % px) & 0xff   // Wrap to 0..px-1 and wrap to 0..255
        let iy1 = ((iy0 + 1) % py) & 0xff   // Wrap to 0..py-1 and wrap to 0..255
        let iz1 = ((iz0 + 1) % pz) & 0xff   // Wrap to 0..pz-1 and wrap to 0..255
        ix0 = (ix0 % px) & 0xff
        iy0 = (iy0 % py) & 0xff
        iz0 = (iz0 % pz) & 0xff

        let r = fade(fz0)
        let t = fade(fy0)
        let s = fade(fx0)

        var nxy0 = grad3(hash: permutations[ix0 + permutations[iy0 + permutations[iz0]]], x: fx0, y: fy0, z: fz0)
        var nxy1 = grad3(hash: permutations[ix0 + permutations[iy0 + permutations[iz1]]], x: fx0, y: fy0, z: fz1)
        var nx0 = lerp(r, nxy0, nxy1)

        nxy0 = grad3(hash: permutations[ix0 + permutations[iy1 + permutations[iz0]]], x: fx0, y: fy1, z: fz0)
        nxy1 = grad3(hash: permutations[ix0 + permutations[iy1 + permutations[iz1]]], x: fx0, y: fy1, z: fz1)
        var nx1 = lerp(r, nxy0, nxy1)

        let n0 = lerp(t, nx0, nx1)

        nxy0 = grad3(hash: permutations[ix1 + permutations[iy0 + permutations[iz0]]], x: fx1, y: fy0, z: fz0)
        nxy1 = grad3(hash: permutations[ix1 + permutations[iy0 + permutations[iz1]]], x: fx1, y: fy0, z: fz1)
        nx0 = lerp(r, nxy0, nxy1)

        nxy0 = grad3(hash: permutations[ix1 + permutations[iy1 + permutations[iz0]]], x: fx1, y: fy1, z: fz0)
        nxy1 = grad3(hash: permutations[ix1 + permutations[iy1 + permutations[iz1]]], x: fx1, y: fy1, z: fz1)
        nx1 = lerp(r, nxy0, nxy1)

        let n1 = lerp(t, nx0, nx1)

        return 0.936 * lerp(s, n0, n1)
    }*/

    static func dnoise(_ vec: float3) -> float3 {
        return float3(dnoise(x: Double(vec.x), y: Double(vec.y), z: Double(vec.z)))
    }

    static func dnoise(x: Double, y: Double, z: Double) -> double3 {
        var ix0 = fastFloor(x)     // Integer part of x
        var iy0 = fastFloor(y)     // Integer part of y
        var iz0 = fastFloor(z)     // Integer part of z
        let fx0 = x - Double(ix0)    // Fractional part of x
        let fy0 = y - Double(iy0)    // Fractional part of y
        let fz0 = z - Double(iz0)    // Fractional part of z

        let fx1 = fx0 - 1.0
        let fy1 = fy0 - 1.0
        let fz1 = fz0 - 1.0
        let ix1 = (ix0 + 1) & 0xff  // Wrap to 0...255
        let iy1 = (iy0 + 1) & 0xff
        let iz1 = (iz0 + 1) & 0xff
        ix0 = ix0 & 0xff
        iy0 = iy0 & 0xff
        iz0 = iz0 & 0xff

        let r = fade(fz0)
        let t = fade(fy0)
        let s = fade(fx0)

        let rp = dfade(fz0, double3(0,0,1))
        let tp = dfade(fy0, double3(0,1,0))
        let sp = dfade(fx0, double3(1,0,0))

        let g000 = gradients[permutations[ix0 + permutations[iy0 + permutations[iz0]]] & 15]
        let p000 = double3(fx0, fy0, fz0)
        let n000 = dot(g000, p000)

        let g001 = gradients[permutations[ix0 + permutations[iy0 + permutations[iz1]]] & 15]
        let p001 = double3(fx0, fy0, fz1)
        let n001 = dot(g001, p001)

        let n00z = lerp(r, n000, n001)
        let n00zp = dlerp(r, n000, n001, rp, g000, g001)

        let g010 = gradients[permutations[ix0 + permutations[iy1 + permutations[iz0]]] & 15]
        let p010 = double3(fx0, fy1, fz0)
        let n010 = dot(g010, p010)

        let g011 = gradients[permutations[ix0 + permutations[iy1 + permutations[iz1]]] & 15]
        let p011 = double3(fx0, fy1, fz1)
        let n011 = dot(g011, p011)

        let n01z = lerp(r, n010, n011)
        let n01zp = dlerp(r, n010, n011, rp, g010, g011)

        let n0yz = lerp(t, n00z, n01z)
        let n0yzp = dlerp(t, n00z, n01z, tp, n00zp, n01zp)

        let g100 = gradients[permutations[ix1 + permutations[iy0 + permutations[iz0]]] & 15]
        let p100 = double3(fx1, fy0, fz0)
        let n100 = dot(g100, p100)

        let g101 = gradients[permutations[ix1 + permutations[iy0 + permutations[iz1]]] & 15]
        let p101 = double3(fx1, fy0, fz1)
        let n101 = dot(g101, p101)

        let n10z = lerp(r, n100, n101)
        let n10zp = dlerp(r, n100, n101, rp, g100, g101)

        let g110 = gradients[permutations[ix1 + permutations[iy1 + permutations[iz0]]] & 15]
        let p110 = double3(fx1, fy1, fz0)
        let n110 = dot(g110, p110)

        let g111 = gradients[permutations[ix1 + permutations[iy1 + permutations[iz1]]] & 15]
        let p111 = double3(fx1, fy1, fz1)
        let n111 = dot(g111, p111)

        let n11z = lerp(r, n110, n111)
        let n11zp = dlerp(r, n110, n111, rp, g110, g111)

        let n1yz = lerp(t, n10z, n11z)
        let n1yzp = dlerp(t, n10z, n11z, tp, n10zp, n11zp)

        return 0.936 * dlerp(s, n0yz, n1yz, sp, n0yzp, n1yzp)
    }

    static func noise(x: Double, y: Double, z: Double, w: Double) -> Double {
        var ix0 = fastFloor(x)     // Integer part of x
        var iy0 = fastFloor(y)     // Integer part of y
        var iz0 = fastFloor(z)     // Integer part of z
        var iw0 = fastFloor(w)     // Integer part of w
        let fx0 = x - Double(ix0)    // Fractional part of x
        let fy0 = y - Double(iy0)    // Fractional part of y
        let fz0 = z - Double(iz0)    // Fractional part of z
        let fw0 = w - Double(iw0)    // Fractional part of z

        let fx1 = fx0 - 1.0
        let fy1 = fy0 - 1.0
        let fz1 = fz0 - 1.0
        let fw1 = fw0 - 1.0
        let ix1 = (ix0 + 1) & 0xff  // Wrap to 0...255
        let iy1 = (iy0 + 1) & 0xff
        let iz1 = (iz0 + 1) & 0xff
        let iw1 = (iw0 + 1) & 0xff
        ix0 = ix0 & 0xff
        iy0 = iy0 & 0xff
        iz0 = iz0 & 0xff
        iw0 = iw0 & 0xff

        let q = fade(fw0)
        let r = fade(fz0)
        let t = fade(fy0)
        let s = fade(fx0)

        var nxyz0 = grad4(hash: permutations[ix0 + permutations[iy0 + permutations[iz0 + permutations[iw0]]]], x: fx0, y: fy0, z: fz0, t: fw0)
        var nxyz1 = grad4(hash: permutations[ix0 + permutations[iy0 + permutations[iz0 + permutations[iw1]]]], x: fx0, y: fy0, z: fz0, t: fw1)
        var nxy0 = lerp(q, nxyz0, nxyz1)

        nxyz0 = grad4(hash: permutations[ix0 + permutations[iy0 + permutations[iz1 + permutations[iw0]]]], x: fx0, y: fy0, z: fz1, t: fw0)
        nxyz1 = grad4(hash: permutations[ix0 + permutations[iy0 + permutations[iz1 + permutations[iw1]]]], x: fx0, y: fy0, z: fz1, t: fw1)
        var nxy1 = lerp(q, nxyz0, nxyz1)

        var nx0 = lerp(r, nxy0, nxy1)

        nxyz0 = grad4(hash: permutations[ix0 + permutations[iy1 + permutations[iz0 + permutations[iw0]]]], x: fx0, y: fy1, z: fz0, t: fw0)
        nxyz1 = grad4(hash: permutations[ix0 + permutations[iy1 + permutations[iz0 + permutations[iw1]]]], x: fx0, y: fy1, z: fz0, t: fw1)
        nxy0 = lerp(q, nxyz0, nxyz1)

        nxyz0 = grad4(hash: permutations[ix0 + permutations[iy1 + permutations[iz1 + permutations[iw0]]]], x: fx0, y: fy1, z: fz1, t: fw0)
        nxyz1 = grad4(hash: permutations[ix0 + permutations[iy1 + permutations[iz1 + permutations[iw1]]]], x: fx0, y: fy1, z: fz1, t: fw1)
        nxy1 = lerp(q, nxyz0, nxyz1)

        var nx1 = lerp(r, nxy0, nxy1)

        let n0 = lerp(t, nx0, nx1)

        nxyz0 = grad4(hash: permutations[ix1 + permutations[iy0 + permutations[iz0 + permutations[iw0]]]], x: fx1, y: fy0, z: fz0, t: fw0)
        nxyz1 = grad4(hash: permutations[ix1 + permutations[iy0 + permutations[iz0 + permutations[iw1]]]], x: fx1, y: fy0, z: fz0, t: fw1)
        nxy0 = lerp(q, nxyz0, nxyz1)

        nxyz0 = grad4(hash: permutations[ix1 + permutations[iy0 + permutations[iz1 + permutations[iw0]]]], x: fx1, y: fy0, z: fz1, t: fw0)
        nxyz1 = grad4(hash: permutations[ix1 + permutations[iy0 + permutations[iz1 + permutations[iw1]]]], x: fx1, y: fy0, z: fz1, t: fw1)
        nxy1 = lerp(q, nxyz0, nxyz1)

        nx0 = lerp(r, nxy0, nxy1)

        nxyz0 = grad4(hash: permutations[ix1 + permutations[iy1 + permutations[iz0 + permutations[iw0]]]], x: fx1, y: fy1, z: fz0, t: fw0)
        nxyz1 = grad4(hash: permutations[ix1 + permutations[iy1 + permutations[iz0 + permutations[iw1]]]], x: fx1, y: fy1, z: fz0, t: fw1)
        nxy0 = lerp(q, nxyz0, nxyz1)

        nxyz0 = grad4(hash: permutations[ix1 + permutations[iy1 + permutations[iz1 + permutations[iw0]]]], x: fx1, y: fy1, z: fz1, t: fw0)
        nxyz1 = grad4(hash: permutations[ix1 + permutations[iy1 + permutations[iz1 + permutations[iw1]]]], x: fx1, y: fy1, z: fz1, t: fw1)
        nxy1 = lerp(q, nxyz0, nxyz1)

        nx1 = lerp(r, nxy0, nxy1)

        let n1 = lerp(t, nx0, nx1)

        return 0.87 * lerp(s, n0, n1)
    }

    static func periodicNoise(x: Double, y: Double, z: Double, w: Double, px: Int, py: Int, pz: Int, pw: Int) -> Double {
        var ix0 = fastFloor(x)     // Integer part of x
        var iy0 = fastFloor(y)     // Integer part of y
        var iz0 = fastFloor(z)     // Integer part of z
        var iw0 = fastFloor(w)     // Integer part of w
        let fx0 = x - Double(ix0)    // Fractional part of x
        let fy0 = y - Double(iy0)    // Fractional part of y
        let fz0 = z - Double(iz0)    // Fractional part of z
        let fw0 = w - Double(iw0)    // Fractional part of z

        let fx1 = fx0 - 1.0
        let fy1 = fy0 - 1.0
        let fz1 = fz0 - 1.0
        let fw1 = fw0 - 1.0
        let ix1 = ((ix0 + 1) % px) & 0xff   // Wrap to 0..px-1 and wrap to 0..255
        let iy1 = ((iy0 + 1) % py) & 0xff   // Wrap to 0..py-1 and wrap to 0..255
        let iz1 = ((iz0 + 1) % pz) & 0xff   // Wrap to 0..pz-1 and wrap to 0..255
        let iw1 = ((iw0 + 1) % pw) & 0xff   // Wrap to 0..pw-1 and wrap to 0..255
        ix0 = (ix0 % px) & 0xff
        iy0 = (iy0 % py) & 0xff
        iz0 = (iz0 % pz) & 0xff
        iw0 = (iw0 % pw) & 0xff

        let q = fade(fw0)
        let r = fade(fz0)
        let t = fade(fy0)
        let s = fade(fx0)

        var nxyz0 = grad4(hash: permutations[ix0 + permutations[iy0 + permutations[iz0 + permutations[iw0]]]], x: fx0, y: fy0, z: fz0, t: fw0)
        var nxyz1 = grad4(hash: permutations[ix0 + permutations[iy0 + permutations[iz0 + permutations[iw1]]]], x: fx0, y: fy0, z: fz0, t: fw1)
        var nxy0 = lerp(q, nxyz0, nxyz1)

        nxyz0 = grad4(hash: permutations[ix0 + permutations[iy0 + permutations[iz1 + permutations[iw0]]]], x: fx0, y: fy0, z: fz1, t: fw0)
        nxyz1 = grad4(hash: permutations[ix0 + permutations[iy0 + permutations[iz1 + permutations[iw1]]]], x: fx0, y: fy0, z: fz1, t: fw1)
        var nxy1 = lerp(q, nxyz0, nxyz1)

        var nx0 = lerp(r, nxy0, nxy1)

        nxyz0 = grad4(hash: permutations[ix0 + permutations[iy1 + permutations[iz0 + permutations[iw0]]]], x: fx0, y: fy1, z: fz0, t: fw0)
        nxyz1 = grad4(hash: permutations[ix0 + permutations[iy1 + permutations[iz0 + permutations[iw1]]]], x: fx0, y: fy1, z: fz0, t: fw1)
        nxy0 = lerp(q, nxyz0, nxyz1)

        nxyz0 = grad4(hash: permutations[ix0 + permutations[iy1 + permutations[iz1 + permutations[iw0]]]], x: fx0, y: fy1, z: fz1, t: fw0)
        nxyz1 = grad4(hash: permutations[ix0 + permutations[iy1 + permutations[iz1 + permutations[iw1]]]], x: fx0, y: fy1, z: fz1, t: fw1)
        nxy1 = lerp(q, nxyz0, nxyz1)

        var nx1 = lerp(r, nxy0, nxy1)

        let n0 = lerp(t, nx0, nx1)

        nxyz0 = grad4(hash: permutations[ix1 + permutations[iy0 + permutations[iz0 + permutations[iw0]]]], x: fx1, y: fy0, z: fz0, t: fw0)
        nxyz1 = grad4(hash: permutations[ix1 + permutations[iy0 + permutations[iz0 + permutations[iw1]]]], x: fx1, y: fy0, z: fz0, t: fw1)
        nxy0 = lerp(q, nxyz0, nxyz1)

        nxyz0 = grad4(hash: permutations[ix1 + permutations[iy0 + permutations[iz1 + permutations[iw0]]]], x: fx1, y: fy0, z: fz1, t: fw0)
        nxyz1 = grad4(hash: permutations[ix1 + permutations[iy0 + permutations[iz1 + permutations[iw1]]]], x: fx1, y: fy0, z: fz1, t: fw1)
        nxy1 = lerp(q, nxyz0, nxyz1)

        nx0 = lerp(r, nxy0, nxy1)

        nxyz0 = grad4(hash: permutations[ix1 + permutations[iy1 + permutations[iz0 + permutations[iw0]]]], x: fx1, y: fy1, z: fz0, t: fw0)
        nxyz1 = grad4(hash: permutations[ix1 + permutations[iy1 + permutations[iz0 + permutations[iw1]]]], x: fx1, y: fy1, z: fz0, t: fw1)
        nxy0 = lerp(q, nxyz0, nxyz1)

        nxyz0 = grad4(hash: permutations[ix1 + permutations[iy1 + permutations[iz1 + permutations[iw0]]]], x: fx1, y: fy1, z: fz1, t: fw0)
        nxyz1 = grad4(hash: permutations[ix1 + permutations[iy1 + permutations[iz1 + permutations[iw1]]]], x: fx1, y: fy1, z: fz1, t: fw1)
        nxy1 = lerp(q, nxyz0, nxyz1)

        nx1 = lerp(r, nxy0, nxy1)

        let n1 = lerp(t, nx0, nx1)

        return 0.87 * lerp(s, n0, n1)
    }
}
