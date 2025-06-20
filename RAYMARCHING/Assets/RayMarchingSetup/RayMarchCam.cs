using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class RayMarchCam : MonoBehaviour
{
    [Header("Ray March Settings")]
    public float maxDistance = 100.0f;
    public Color _MainColor;
    [Header("Light Settings")]
    public new Vector3 light; // Use 'new' keyword to explicitly hide the inherited member  
    public float lightIntensity = 1.0f; // This is not used in the shader, but can be useful for other calculations
    public Color lightColor;
    [Header("Shadow Settings")]
    public Vector3 ShadowDistance;
    public float shadowIntensity;

    public float AOIntensity = 0.5f; // Ambient Occlusion intensity, not used in the shader but can be useful for other calculations
    public float AOStepSize = 0.1f; // Ambient Occlusion step size, not used in the shader but can be useful for other calculations
    public float AOIterations = 5; // Ambient Occlusion iterations, not used in the shader but can be useful for other calculations

    public int maxIterations = 200;
    public float stepSize = 0.001f; // Step size for ray marching

    [SerializeField]
    private Shader _rayMarchShader;

    private ComputeBuffer buffer;
    public Material _rayMarchMaterial
    {
        get
        {
            if (!_rayMarchMat && _rayMarchShader)
            {
                _rayMarchMat = new Material(_rayMarchShader);
                _rayMarchMat.hideFlags = HideFlags.HideAndDontSave;
            }

            return _rayMarchMat;
        }
    }

    private Material _rayMarchMat;

    public Camera _camera
    {
        get
        {
            if (!_cam)
            {
                _cam = GetComponent<Camera>();
            }
            return _cam;
        }
    }
    private Camera _cam;

    void Start()
    {
        buffer = new ComputeBuffer(0, 0); 

    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!_rayMarchMaterial)
        {
            Graphics.Blit(source, destination);
            return;

        }
        _rayMarchMaterial.SetMatrix("_CamFrustum", CamFrustum(_camera));
        _rayMarchMaterial.SetMatrix("_CamToWorld", _cam.cameraToWorldMatrix);
        _rayMarchMaterial.SetFloat("_MaxDistance", maxDistance);
        _rayMarchMaterial.SetColor("_MainColor", _MainColor);
        _rayMarchMaterial.SetVector("_Light", light);
        _rayMarchMaterial.SetFloat("_LightIntensity", lightIntensity);
        _rayMarchMaterial.SetColor("_LightColor", lightColor);
        _rayMarchMaterial.SetVector("_ShadowDistance", ShadowDistance);
        _rayMarchMaterial.SetFloat("_ShadowIntensity", shadowIntensity);
        _rayMarchMaterial.SetFloat("_AOIntensity", AOIntensity);
        _rayMarchMaterial.SetFloat("_AOStepSize", AOStepSize);
        _rayMarchMaterial.SetFloat("_AOIterations", AOIterations);
        _rayMarchMaterial.SetVector("_CamPos", _cam.transform.position);
        _rayMarchMaterial.SetInt("_MaxIterations", maxIterations);
        _rayMarchMaterial.SetFloat("_StepSize", stepSize);

        RenderTexture.active = destination;
        GL.PushMatrix();
        GL.LoadOrtho();
        _rayMarchMaterial.SetPass(0);
        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f); // Bottom Left  

        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);

        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);

        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);
        GL.End();
        GL.PopMatrix();
    }

    private Matrix4x4 CamFrustum(Camera cam)
    {
        Matrix4x4 frustum = Matrix4x4.identity;
        float fov = Mathf.Tan((cam.fieldOfView * 0.5f) * Mathf.Deg2Rad);

        Vector3 goUp = Vector3.up * fov;
        Vector3 goRight = Vector3.right * fov * cam.aspect;

        Vector3 TL = (-Vector3.forward + goUp - goRight);
        Vector3 TR = (-Vector3.forward + goUp + goRight);
        Vector3 BR = (-Vector3.forward - goUp + goRight);
        Vector3 BL = (-Vector3.forward - goUp - goRight);

        frustum.SetRow(0, TL);
        frustum.SetRow(1, TR);
        frustum.SetRow(2, BR);
        frustum.SetRow(3, BL);
        return frustum;
    }

}
