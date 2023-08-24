Shader "Custom/Unlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RampTex ("Ramp", 2D) = "white" {}
        //_AmbientLight ("Ambient Light", Color) = (0.5,0.5,0.5,1)
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque" 
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float fogFactor : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            float3 _AmbientLight;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogFactor = ComputeFogFactor(o.vertex.z);
                o.normal = TransformObjectToWorldNormal(v.normal);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float4 fragment_color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                const Light light = GetMainLight();

                // 光と法線の内積をとって光の当たり加減を計算する (-1~1)
                float t = dot(i.normal, light.direction);
                // -1~0は0にする
                t = max(0, t);
                // 光の色を当たり加減に適用 (強く当たっているほど色も強く出る)
                const float3 diffuseLight = light.color * t;
                float3 toonColoredFragment = diffuseLight;
                toonColoredFragment = 1.00 >= toonColoredFragment && toonColoredFragment >= 0.66 ? 1   : toonColoredFragment;
                toonColoredFragment = 0.66 >  toonColoredFragment && toonColoredFragment >= 0.33 ? 0.5 : toonColoredFragment;
                toonColoredFragment = 0.33 >  toonColoredFragment && toonColoredFragment >= 0.00 ? 0   : toonColoredFragment;
                fragment_color.rgb = toonColoredFragment;

                //col.rgb *= diffuseLight + _AmbientLight;

                // apply fog
                fragment_color.rgb = MixFog(fragment_color.rgb, i.fogFactor);
                return fragment_color;
            }
            ENDHLSL
        }
    }
}
