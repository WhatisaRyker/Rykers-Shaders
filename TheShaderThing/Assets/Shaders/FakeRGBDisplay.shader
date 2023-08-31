Shader "RykerPack/FakeRGBDisplay"
{
    Properties
    {
        [Header(Texture map)][Space(15)]_MainTex ("Texture", 2D) = "white" {}
        [IntRange][Header(Fake Screen Options)][Space(15)]_PixelDensity ("Pixel Density", Range(1, 1000)) = 1
        [Range]_Overdrive ("Overdrive", Range(1, 5)) = 0
        [Range]_PixelHardness("Pixel Hardness", Range(0, 1)) = 1
        [Header(Distance blending)][Space(15)][MaterialToggle]_DistanceBlendingToggle("Use Distance Blending?", int) = 1
        _DistanceBlendingStart ("Distance Blending Start", float) = 50
        _DistanceBlendingEnd ("Distance Blending End", float) = 100
        [Header(Red)][Space(15)][Range]_RedPixelDimensionX("Red Pixel Dimesnsion X axis", Range(0,1)) = 0.475
        [Range]_RedPixelDimensionY("Red Pixel Dimesnsion Y axis", Range(0,1)) = 0.975
        [Range]_RedPixelOffsetX("Red Pixel Offset X axis", Range(-0.5 ,0.5)) = 0.25
        [Range]_RedPixelOffsetY("Red Pixel Offset Y axis", Range(-0.5 , 0.5)) = 0
        [Header(Green)][Space(15)][Range]_GreenPixelDimensionX("Green Pixel Dimesnsion X axis", Range(0,1)) = 0.475
        [Range]_GreenPixelDimensionY("Green Pixel Dimesnsion Y axis", Range(0,1)) = 0.475
        [Range]_GreenPixelOffsetX("Green Pixel Offset X axis", Range(-0.5, 0.5)) = -0.25
        [Range]_GreenPixelOffsetY("Green Pixel Offset Y axis", Range(-0.5, 0.5)) = 0.25
        [Header(Blue)][Space(15)][Range]_BluePixelDimensionX("Blue Pixel Dimesnsion X axis", Range(0,1)) = 0.425
        [Range]_BluePixelDimensionY("Blue Pixel Dimesnsion Y axis", Range(0,1)) = 0.425
        [Range]_BluePixelOffsetX("Blue Pixel Offset X axis", Range(-0.5, 0.5)) = -0.25
        [Range]_BluePixelOffsetY("Blue Pixel Offset Y axis", Range(-0.5, 0.5)) = -0.25
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        ZWrite On

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 unUV : TEXCOORD1;
                float dist : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _DistanceBlendingToggle;
            float _DistanceBlendingStart;
            float _DistanceBlendingEnd;
            float _BlendValue;

            float _PixelDensity;
            float _Overdrive;
            float _PixelHardness;
            float _RedPixelDimensionX;
            float _RedPixelDimensionY;
            float _RedPixelOffsetX;
            float _RedPixelOffsetY;
            float _GreenPixelDimensionX;
            float _GreenPixelDimensionY;
            float _GreenPixelOffsetX;
            float _GreenPixelOffsetY;
            float _BluePixelDimensionX;
            float _BluePixelDimensionY;
            float _BluePixelOffsetX;
            float _BluePixelOffsetY;

            float blendedSin(float input, float blending) 
            {
                float Pi = 3.14159265359;
                float outputValue = (cos(input * (Pi)) + 0.5);
                return lerp(outputValue, round(outputValue) , blending);
            }

            fixed checkColor(half2 uvPoint, float blendValue, float xOffset, float yOffset, float xScale, float yScale)
            {
                if(_DistanceBlendingToggle == 1) {
                    blendValue -= (_DistanceBlendingStart / sqrt(_PixelDensity));
                    blendValue /= _DistanceBlendingEnd - (_DistanceBlendingStart / sqrt(_PixelDensity));
                    blendValue = clamp(blendValue, 0, 1);
                    xOffset = lerp(xOffset, 0, blendValue);
                    yOffset = lerp(yOffset, 0, blendValue);
                    xScale = lerp(xScale, 1, blendValue);
                    yScale = lerp(yScale, 1, blendValue);
                }
                float2 localPoint = float2((uvPoint.x + (xOffset - 0.5)) / xScale, (uvPoint.y + (yOffset - 0.5)) / yScale);

                if(localPoint.x > 0.5 || localPoint.x < -0.5)
                    return 0;

                if(localPoint.y > 0.5 || localPoint.y < -0.5)
                    return 0;

                half output = blendedSin(localPoint.x, _PixelHardness) * blendedSin(localPoint.y, _PixelHardness);         
                return output;
            }

            fixed4 applyScreenColor(float2 uvPoint, sampler2D Tex, float distance)
            {
                float2 texturePoint = (floor(uvPoint * _PixelDensity) + 0.5) / _PixelDensity;
                half2 localPoint = half2(frac(uvPoint.x * _PixelDensity), frac(uvPoint.y * _PixelDensity));
                float4 textureColor = tex2D(Tex, texturePoint);
                fixed4 Color = fixed4(0, 0, 0, 1);

                Color.r = checkColor(localPoint, distance, _RedPixelOffsetX, _RedPixelOffsetY, _RedPixelDimensionX, _RedPixelDimensionY) / 2;
                Color.g = checkColor(localPoint, distance, _GreenPixelOffsetX, _GreenPixelOffsetY, _GreenPixelDimensionX, _GreenPixelDimensionY);
                Color.b = checkColor(localPoint, distance, _BluePixelOffsetX, _BluePixelOffsetY, _BluePixelDimensionX, _BluePixelDimensionY);

                return Color * textureColor;

            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;   
                o.dist = distance(_WorldSpaceCameraPos, mul(unity_ObjectToWorld, v.vertex));
                o.unUV = v.uv;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = applyScreenColor(i.uv, _MainTex, i.dist);
                return col;
            }
            ENDCG
        }

        Pass
        {
            Tags {"LightMode" = "ShadowCaster"}
            ZWrite On
            CGPROGRAM
            #pragma vertex vert_shadow
            #pragma fragment frag_shadow
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing // allow instanced shadow pass for most of the shaders
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityShadowLibrary.cginc"
            struct v2f_shadow
            {
                V2F_SHADOW_CASTER_NOPOS UNITY_POSITION(pos);
                float2  uv : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            v2f_shadow vert_shadow(appdata_tan v)
            {
                v2f_shadow o;
                v.vertex.xyz += GetWindNoise(v.texcoord, v.vertex);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }
            float4 frag_shadow(v2f_shadow i) : SV_Target
            {
                fixed4 texcol = tex2D(_MainTex, i.uv);
                clip(texcol.a - _Cutoff);
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
