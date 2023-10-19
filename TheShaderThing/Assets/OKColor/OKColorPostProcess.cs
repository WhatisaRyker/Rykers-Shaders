using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class OKColorPostProcess : MonoBehaviour
{
    private Material OKColor;
    [SerializeField] Shader OKShader;
    [Range(1, 16)]
    public int NumberOfColors = 8;
    [Range(0f, 1f)]
    public float LightnessRange = 0.788f;
    [Range(0.001f, 1f)]
    public float LightnessOffset = 0.37f;
    [Range(0f, 1f)]
    public float InitialSaturation = 0.707f;
    [Range(-1f, 1f)]
    public float ChromaRange = 0.54f;
    [Range(0f, 1f)]
    public float ChromaOffset = 0.568f;
    [Range(0f, 1f)]
    public float DitherSpread = 0.080f;
    [Range(0, 16)]
    public int DitherScale = 3;

    private void Start()
    {
        OKColor = new Material(OKShader);
        UpdateProperties();
    }

    private void UpdateProperties()
    {
        OKColor.SetInt("_NumOfColors", NumberOfColors);
        OKColor.SetFloat("_LightnessRange", LightnessRange);
        OKColor.SetFloat("_LightnessOffset", LightnessOffset);
        OKColor.SetFloat("_InitSat", InitialSaturation);
        OKColor.SetFloat("_ChromaRange", ChromaRange);
        OKColor.SetFloat("_ChromaOffset", ChromaOffset);
        OKColor.SetFloat("_DitherSpread", DitherSpread);
        OKColor.SetInt("_DitherScale", DitherScale);
    }

    private void Update()
    {
        UpdateProperties();
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, OKColor);
    }
}
