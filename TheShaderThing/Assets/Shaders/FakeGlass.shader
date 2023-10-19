Shader "RykerPack/Glass"
{
    Properties {
        [Header(Color Maps)][Space(15)][MaterialToggle] _UseColorBias("Use Color Bias?", float) = 0
        _ColorBiasTexture("Bias Texture", 2D) = "white" {}
        [Range]_ColorBias("Color Bias", Range(0, 1)) = 1
        [Header(TintColor)][Space(15)][MaterialToggle] _UseTintColor("Use Tint Color?", float) = 0
        [HDR] _GlassTint("Glass Tint Color", Color) = (1,1,1,1)
        [Header(Noise and distortion)][Space(15)]_NoiseTex("Noise Texture", 2D) = "bump" {}
        [Range]_Distortion("Distortion", Range(0, 1)) = 0.2
        [Header(Fresnel Effects)][Space(15)][MaterialToggle] _UseFresnel("Use Fresnel?", float) = 0
        _FresnelPower("Fresnel Power", float) = 0
        [HDR] _FresnelColor("Fresnel Color", Color) = (1,1,1,1)
        [KeywordEnum(Add, Mul)]_FresnelType("Fresnel Color Application", int) = 0
        [Header(Random Square One Pass Blur)][Space(15)][MaterialToggle] _UseRandomBlur("Use Random Blur?", float) = 0
        [Range]_RandomBlurRadius("Random Blur Radius", Range(0, 10)) = 0.1
        [Header(Random Circle Blur)][Space(15)][MaterialToggle] _UseHighQualityBlur("Use High Quality Blur?", float) = 0
        [IntRange]_BlurQualitySteps("Blur Quality Steps", Range(1, 200)) = 4
        [Range]_HQBlurRadius("High Quality Blur Radius", Range(0, 50)) = 1
        [Header(Procedural Circle Blur)][Space(15)][MaterialToggle] _UseBlur("Use Blur?", float) = 0
        [MaterialToggle] _UseBlurTex("Use Noise Texture for blur?", float) = 0
        _BlurTex("Blur Texture", 2D) = "bump" {}
        [IntRange]_BlurDirections("Blur Directions", Range(1, 64)) = 16
        [IntRange]_BlurQuality("Blur Quality", Range(0, 100)) = 3
        [Range]_BlurRadius("Blur Radius", Range(0, 5)) = 4
        [Header(BlurSettings)][Space(15)][MaterialToggle] _UseDistanceBlur("Use distance weighting", int) = 1
        [Range]_DistanceBlurWeighting("Distance blur weighting", Range(0, 1)) = 1
        [Header(Other)][Space(15)][Range]_IQR("IQR", Range(-1, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }

        GrabPass 
        {
            "_RenderTexture"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.0
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float4 grabPos: TEXCOORD0;
                float2 textcoord: TEXCOORD1;
                half3 normal : TEXCOORD2;
                float2 colorBiasCoord : TEXCOORD3;
                float3 worldNorm : TEXCOORD4;
                float3 viewDir : TEXCOORD5;
                float4 pos : SV_POSITION;
            };
            
            sampler2D _RenderTexture;
            sampler2D _CameraDepthTexture;
            sampler2D _ColorBiasTexture;
            sampler2D _NoiseTex;
            float4 _GlassTint;
            float4 _FresnelColor;
            float4 _NoiseTex_ST;
            float4 _ColorBiasTexture_ST;
            float _UseTintColor;
            float _UseNoise;
            float _Distortion;
            float _IQR;
            float _ColorBias;
            float _UseColorBias;

            float _UseFresnel;
            float _FresnelPower;
            int _FresnelType;

            float _UseRandomBlur;
            float _RandomBlurRadius;

            float _UseHighQualityBlur;
            int _BlurQualitySteps;
            float _HQBlurRadius;

            float _UseBlur;
            float _BlurDirections;
            float _BlurQuality;
            float _BlurRadius;

            sampler2D _BlurTex;
            float4 _BlurTex_ST;
            int _UseDistanceBlur;
            float _DistanceBlurWeighting;


            float NormalizedTriangle (float x)
            {
                float Pi = 3.141592653;
                return ( ( Pi / 2 ) * ( asin( sin( x*Pi ) ) ) + 1) / 2;
            }

            float4 ApplyBlur (sampler2D Texture, fixed4 uv)
            {
                    float Pi = 6.28318530718; // Pi*2

                // GAUSSIAN BLUR SETTINGS {{{
                float Directions = _BlurDirections; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
                float Quality = _BlurQuality; // BLUR QUALITY (Default 4.0 - More is better but slower)
                float Radius = _BlurRadius / 10; // BLUR SIZE (Radius)
                // GAUSSIAN BLUR SETTINGS }}}
                // Pixel colour
                float4 Color = tex2D(Texture, uv) / (Quality * Directions);

                // Blur calculations
                for( float d =0.0; d < Pi; d += Pi/Directions) {
                    for(float i=1.0 / Quality; i <= 1.0; i += 1.0 / Quality) {
	            		Color += clamp(tex2D( Texture, uv + float4(cos(d),sin(d), 0, 0)*Radius*i), 0, 1) / (Quality * Directions);
                    }
                }	
                return Color;
            }

            float3 hashOld33( float3 p )
            {
            	p = float3( dot(p,float3(127.1,311.7, 74.7)),
            			  dot(p,float3(269.5,183.3,246.1)),
            			  dot(p,float3(113.5,271.9,124.6)));

            	return frac(sin(p)*43758.5453123);
            }

            
            float4 randomblur(float4 input, float intensity) 
            {
                input.xyz = input.xyz + ((hashOld33(input.xyz) - 0.5) * (intensity/100));

                return input;
            }

            float4 betterblur(float4 input, float4 seed, float intensity) 
            {
                float Pi = 6.28318530718;
                float3 output = ((hashOld33(seed.xyz)));
                input.xyz += float3(output.x * cos(output.y * Pi), output.x * sin(output.y * Pi), 0) * (intensity / 100);
                return input;
            }

            float4 GetRandomHighQuality(float4 input, sampler2D _Texture, float4 seed) 
            {
                float Pi = 6.28318530718; // Pi*2
                float steps = _BlurQualitySteps;
                float blurRad = _HQBlurRadius;

                if(_UseDistanceBlur) {
                    blurRad * UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, (input)));
                }

                float4 Color = clamp(tex2D(_Texture, input), 0, 1) / (steps + 1);
                float4 uv = float4(0, 0, 0, 0);
                for(float i = 0; i < steps; i++) {
                    uv = betterblur(input, normalize(seed + i), blurRad);
                    Color += clamp(tex2D(_Texture, uv), 0, 1) / (steps + 1);
                }
                return Color;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.textcoord = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.colorBiasCoord = TRANSFORM_TEX(v.uv, _ColorBiasTexture);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // compute world space view direction
                o.viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                o.worldNorm = UnityObjectToWorldNormal(v.normal);
                o.normal = normalize( mul(float4(v.normal, 0.0), unity_WorldToObject));
                o.grabPos = ComputeGrabScreenPos(o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 bump = fixed4( UnpackNormal(tex2D(_NoiseTex, i.textcoord)), 0);
                bump = normalize(bump); 
                fixed3 norm = i.normal;
                float2 screenPosition = (i.grabPos.xy / i.grabPos.w);

                fixed4 DistNorm = float4(refract(i.viewDir, normalize(i.worldNorm), _IQR), 0);
                fixed2 DistUV = screenPosition + (bump * _Distortion);

                DistUV = DistUV + DistNorm;

                fixed4 refraction;
                fixed4 refractionN;
                if(_UseRandomBlur == 0 && _UseHighQualityBlur == 0 && _UseBlur == 0 ) {
                    refraction = tex2D(_RenderTexture, UNITY_PROJ_COORD(DistUV));
                    refractionN = tex2D(_RenderTexture, UNITY_PROJ_COORD(screenPosition));
                }

                if(_UseRandomBlur == 1) {
                    refraction = tex2D(_RenderTexture, UNITY_PROJ_COORD(randomblur(DistUV, _RandomBlurRadius)));
                    refractionN = tex2D(_RenderTexture, UNITY_PROJ_COORD(randomblur(screenPosition, _RandomBlurRadius)));
                }
                    
                if(_UseHighQualityBlur == 1) {
                    refraction = GetRandomHighQuality(UNITY_PROJ_COORD(DistUV), _RenderTexture, i.pos);
                    refractionN = GetRandomHighQuality(UNITY_PROJ_COORD(screenPosition), _RenderTexture, i.pos);
                }
                
                if(_UseBlur == 1) {
                    refraction = ApplyBlur(_RenderTexture, UNITY_PROJ_COORD(DistUV));
                    refractionN = ApplyBlur(_RenderTexture, UNITY_PROJ_COORD(screenPosition));
                }

                fixed refrFix = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, UNITY_PROJ_COORD(DistUV)));

                if(LinearEyeDepth(refrFix) < i.grabPos.z)
                         refraction = refractionN;
                fixed4 tint = float4(0,0,0,0);
                fixed3 finalColor = refraction.rgb;
                if(_UseColorBias == 1) {
                    tint = tex2D(_ColorBiasTexture, i.colorBiasCoord) * _ColorBias;
                    finalColor = refraction.rgb + tint - (refraction.rgb * tint);
                    //finalColor = refraction.rgb + tint;
                    //finalColor = refraction.rgb * tint; mul
                }

                if(_UseTintColor == 1) {
                    finalColor = finalColor * _GlassTint;
                }
            
                if(_UseFresnel == 1) {
                    if(_FresnelType == 0) {
                        finalColor = finalColor + (pow(saturate(1 - dot(normalize(i.worldNorm), normalize(i.viewDir))), _FresnelPower) * _FresnelColor);
                    }
                    if(_FresnelType == 1) {
                        finalColor = finalColor * (pow(saturate(dot(normalize(i.worldNorm), normalize(i.viewDir))), _FresnelPower) * _FresnelColor);
                    }
                }

                return fixed4(finalColor, 1);
            }
            ENDCG
        }
    }
}
