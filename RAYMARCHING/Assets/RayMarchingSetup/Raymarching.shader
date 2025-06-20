

Shader "PeerPlay/Raymarching"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "DistanceFunctions.cginc"

            sampler2D _MainTex;
            

            uniform float4x4 _CamFrustum,_CamToWorld;
            uniform float _MaxDistance;
            uniform float3 _Light;
            uniform float4 _MainColor;
            uniform float3 _LightColor;
            uniform float3 _ShadowDistance;
            uniform float _LightIntensity;
            uniform float _ShadowIntensity;
            uniform float _AOStepSize;
            uniform float _AOIterations;
            uniform float _AOIntensity;
            uniform float3 _CamPos;
            uniform int _MaxIterations;
            uniform float _StepSize;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ray : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0.0; // set z to 0 to avoid depth issues
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.ray = _CamFrustum[(int)index].xyz;

                o.ray /= abs(o.ray.z);
                
                o.ray = mul(_CamToWorld, o.ray);

                return o;
            }

            
            
            float signedDistanceFunction2(float3 position)
            {
                //position = position*2;
            //position= addNoise(position,0.5,3); // Add noise to the position for more organic shapes
            float time= remap(sin(_Time.x*10),-1,1,-2,2);
            float3 pos = float3(0,2.5+time,0);
            //position = position%10.0-5; // Wrap position to a smaller range for simplicity)
            float3 rotatedPos = rotateAroundAxis(position, float3(0,1,0), _Time.x*10); // Rotate the position around the Y-axis)

             float sp1 = sdSphere(position-pos,2.0);
             sp1 = smin(sp1,sdBox(rotatedPos-pos,float3(10,0.5,0.5)),0.6); 
             float sp2 = sdBox(position, float3(2.0,2.0,2.0));
             float box = sdPlane(position,float3(0,1,0),+5);
             float minv = remap(sin(_Time.x*20),-1,1,0.01,0.5);
             //return smin(sp1,sp2,0.2);
             return min(smin(sp1, sp2,minv),box); // Use the union operation to combine the two spheres)

            }
            
            float signedDistanceFunction(float3 position)
            {
             position = abs(position)%2-1;
             float s1 = sdSphere(position,0.3);
             float sf =remap(sin(_Time.x*10),-1,1,0.01,0.1);
             //float3 rotatedPos = rotateAroundAxis(position, float3(0,1,0), _Time.x*10); // Rotate the position around the Y-axis)
             float s2 = sdBox(position,float3(0.5,0.1,0.1));
             
             //float box = smin(s1,s2,sf);
             float box = min(s1,s2);
             return box; // Use the union operation to combine the two spheres)

            }


            float3 normal(float3 p){

                float2 offset = float2(0.001,0);
                float3 n = float3(
                    signedDistanceFunction(p-offset.xyy)-signedDistanceFunction(p+offset.xyy),
                    signedDistanceFunction(p-offset.yxy)-signedDistanceFunction(p+offset.yxy),
                    signedDistanceFunction(p-offset.yyx)-signedDistanceFunction(p+offset.yyx)

                    );
                return normalize(n);

                }
            float hardShadows(float3 rayOrigin, float3 rayDirection, float mint, float maxt)
            {
               for (float t = mint; t < maxt;)
                {
                    float3 position = rayOrigin + rayDirection * t;
                    float distance = signedDistanceFunction(position);
                    if (distance < 0.001) // If we hit an object
                    {
                        return 0.0; // Shadow
                    }
                    t+=distance;
                }
                return 1.0; // No shadow
            }

            float softShadows(float3 rayOrigin, float3 rayDirection, float mint, float maxt, float blur)
            {
               float result = 1.0;
               for (float t = mint; t < maxt;)
                {
                    float3 position = rayOrigin + rayDirection * t;
                    float distance = signedDistanceFunction(position);
                    if (distance < 0.001) // If we hit an object
                    {
                        return 0.0; // Shadow
                    }
                    result = min(result, blur*distance / t);
                    t+=distance;
                }
                return result; // No shadow
            }

            float ambientOcclusion(float3 position, float3 normal)
            {
                float step =_AOStepSize;
                float ao =0.0;
                float distance;

                for (int i = 1; i < _AOIterations; i++)
                {
                    distance = step*i;
                    ao+= max(0.0,(distance - signedDistanceFunction(position + normal*distance))/distance);
                    
                }
                return(1.0-ao*_AOIntensity);
            }

            float shading(float3 position, float3 normal)
            {

                // Simple Lambertian shading
                float lambert = _LightColor*(dot(normal, _Light)*0.5+0.5)*_LightIntensity;

                float shadow = softShadows(position, -_Light, _ShadowDistance.x,_ShadowDistance.y,_ShadowDistance.z)*0.5+0.5;
                shadow=max(0.0,pow(shadow,_ShadowIntensity));
                float ao = ambientOcclusion(position, normal);

                //return lambert*shadow*ao;
                return ao;
            }

            fixed4 rayMarching(float3 rayOrigin, float3 rayDirection)
            {
                //return(fixed4(rayDirection,1));
                // Placeholder for ray marching logic
                // This function should return the color based on the ray marching algorithm
                fixed4 result = fixed4(0, 0, 0, 1); // Default color (black)
                const int maxIterations = _MaxIterations; 
                float distanceTraveled = 0.0;
                
             
                for (int it=0;it< maxIterations; it++)
                {
                    if(distanceTraveled > _MaxDistance) // If we exceed the maximum distance, we stop
                    {
                        //BACKGROUND
                        result = fixed4(0,0,0, 1); // Background color (black)
                        break;
                    }
                    float3 position = rayOrigin + distanceTraveled * rayDirection;
                    
                    float stepSize = signedDistanceFunction(position);

                    if (stepSize < _StepSize) // If the step size is small enough, we assume we hit an object
                    {
                        //shading
                        float3 n =normal(position);
                        

                        result = fixed4(_MainColor.rgb*shading(position,n),1); 
                        break;
                    }
                    
                    distanceTraveled += stepSize; // Move the ray forward by the step size
                    // Here you would typically sample a distance field or perform some calculations
                    // to determine if the ray intersects with an object in the scene.    
                }

                return result;
            }

            

            
           

            fixed4 frag (v2f i) : SV_Target
            {
                
                float3 rayDirection = normalize(i.ray.xyz);
                float3 rayOrigin = _CamPos;

                float2 uv = i.uv;
                

                
                
                fixed4 color = rayMarching(rayOrigin, rayDirection);
                fixed4 colorb= fixed4(rayDirection,1); // Background color (black)
                return color; 
            }
            ENDCG
        }
    }
}
