// Sphere
// s: radius
float sdSphere(float3 p, float s)
{
	return length(p) - s;
}

float sdCone(float3 p, float2 c, float h)
{
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
    float2 q = h * float2(c.x / c.y, -1.0);
    
    float2 w = float2(length(p.xz), p.y);
    float2 a = w - q * clamp(dot(w, q) / dot(q, q), 0.0, 1.0);
    float2 b = w - q * float2(clamp(w.x / q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a, a), dot(b, b));
    float s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
    return sqrt(d) * sign(s);
}
// Box
// b: size of box in x/y/z
float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) +
		length(max(d, 0.0));
}

float sdPlane(float3 p, float3 n, float d)
{
    return dot(p, n) + d;
}

// BOOLEAN OPERATORS //

// Union
float opU(float d1, float d2)
{
	return min(d1, d2);
}

// Subtraction
float opS(float d1, float d2)
{
	return max(-d1, d2);
}

// Intersection
float opI(float d1, float d2)
{
	return max(d1, d2);
}

// Mod Position Axis
float pMod1 (inout float p, float size)
{
	float halfsize = size * 0.5;
	float c = floor((p+halfsize)/size);
	p = fmod(p+halfsize,size)-halfsize;
	p = fmod(-p+halfsize,size)-halfsize;
	return c;
}

float remap(float v, float minOld, float maxOld, float minNew, float maxNew)
{
    return minNew + (v - minOld) * (maxNew - minNew) / (maxOld - minOld);
}

float smin(float a, float b, float k)
{
    k *= 2.0;
    float x = b - a;
    return 0.5 * (a + b - sqrt(x * x + k * k));
    
}

float smax(float a, float b, float k)
{
    return -smin(-a, -b, k);
}

float sS(float a, float b, float k)
{
    return smax(a, -b, k); // use smoothMax if you implement it similarly
}
            

float mod289(float x)
{
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}
float4 mod289(float4 x)
{
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}
float4 perm(float4 x)
{
    return mod289(((x * 34.0) + 1.0) * x);
}

float noise(float3 p)
{
    float3 a = floor(p);
    float3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    float4 b = a.xxyy + float4(0.0, 1.0, 0.0, 1.0);
    float4 k1 = perm(b.xyxy);
    float4 k2 = perm(k1.xyxy + b.zzww);

    float4 c = k2 + a.zzzz;
    float4 k3 = perm(c);
    float4 k4 = perm(c + 1.0);

    float4 o1 = frac(k3 * (1.0 / 41.0));
    float4 o2 = frac(k4 * (1.0 / 41.0));

    float4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    float2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float3 addNoise(float3 position, float scale, float intensity)
{
    return position + remap(noise(position * scale), 0, 1, -1, 1) * intensity; // Offset to avoid negative values
}

float3 rotateAroundAxis(float3 p, float3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    float3x3 R = float3x3(
        oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
        oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c
    );

    return mul(R, p);
}