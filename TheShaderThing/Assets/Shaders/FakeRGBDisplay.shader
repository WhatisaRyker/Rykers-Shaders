Shader "RykerPack/FakeRGBDisplay"
{
    Properties
    {
        [Header(Texture map and options)][Space(15)]_MainTex ("Texture", 2D) = "white" {}
        [IntRange][Header(Fake Screen Options)][Space(15)]_PixelDensity ("Pixel Density", Range(1, 1000)) = 1
        [Range]_Overdrive ("Overdrive", Range(1, 5)) = 0
        [Range]_PixelHardness("Pixel Hardness", Range(0, 1)) = 0
        [Header(Red)][Space(15)][Range]_RedPixelDimensionX("Red Pixel Dimesnsion X axis", Range(0,1)) = 0.425
        [Range]_RedPixelDimensionY("Red Pixel Dimesnsion Y axis", Range(0,1)) = 0.95
        [Range]_RedPixelOffsetX("Red Pixel Offset X axis", Range(-0.5 ,0.5)) = 0.25
        [Range]_RedPixelOffsetY("Red Pixel Offset Y axis", Range(-0.5 , 0.5)) = 0.5
        [Header(Green)][Space(15)][Range]_GreenPixelDimensionX("Green Pixel Dimesnsion X axis", Range(0,1)) = 0.425
        [Range]_GreenPixelDimensionY("Green Pixel Dimesnsion Y axis", Range(0,1)) = 0.425
        [Range]_GreenPixelOffsetX("Green Pixel Offset X axis", Range(-0.5, 0.5)) = 0.75
        [Range]_GreenPixelOffsetY("Green Pixel Offset Y axis", Range(-0.5, 0.5)) = 0.25
        [Header(Blue)][Space(15)][Range]_BluePixelDimensionX("Blue Pixel Dimesnsion X axis", Range(0,1)) = 0.425
        [Range]_BluePixelDimensionY("Blue Pixel Dimesnsion Y axis", Range(0,1)) = 0.425
        [Range]_BluePixelOffsetX("Blue Pixel Offset X axis", Range(-0.5, 0.5)) = 0.75
        [Range]_BluePixelOffsetY("Blue Pixel Offset Y axis", Range(-0.5, 0.5)) = 0.25
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

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

            fixed checkColor(half2 uvPoint, float xOffset, float yOffset, float xScale, float yScale)
            {
                float2 localPoint = float2((uvPoint.x + (xOffset - 0.5)) / xScale, (uvPoint.y + (yOffset - 0.5)) / yScale);

                if(localPoint.x > 0.5 || localPoint.x < -0.5)
                    return 0;

                if(localPoint.y > 0.5 || localPoint.y < -0.5)
                    return 0;

                half output = blendedSin(localPoint.x, _PixelHardness) * blendedSin(localPoint.y, _PixelHardness);         
                return output;
            }

            fixed4 applyScreenColor(float2 uvPoint, sampler2D Tex)
            {
                float2 texturePoint = (floor(uvPoint * _PixelDensity) + 0.5) / _PixelDensity;
                half2 localPoint = half2(frac(uvPoint.x * _PixelDensity), frac(uvPoint.y * _PixelDensity));
                float4 textureColor = tex2D(Tex, texturePoint);
                fixed4 Color = fixed4(0, 0, 0, 1);

                Color.r = checkColor(localPoint, _RedPixelOffsetX, _RedPixelOffsetY, _RedPixelDimensionX, _RedPixelDimensionY) / 2;
                Color.g = checkColor(localPoint, _GreenPixelOffsetX, _GreenPixelOffsetY, _GreenPixelDimensionX, _GreenPixelDimensionY);
                Color.b = checkColor(localPoint, _BluePixelOffsetX, _BluePixelOffsetY, _BluePixelDimensionX, _BluePixelDimensionY);

                return Color * textureColor;

            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.unUV = v.uv;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = applyScreenColor(i.uv, _MainTex);
                return col;
            }
            ENDCG
        }
    }
}
