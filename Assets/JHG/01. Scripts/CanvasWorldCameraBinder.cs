using UnityEngine;

[RequireComponent(typeof(Canvas))]
public class CanvasWorldCameraBinder : MonoBehaviour
{
    [Tooltip("원하면 여기 직접 할당. 비워두면 자동 탐색.")]
    public Camera overrideCamera;

    [Tooltip("자동 탐색 시, 이 문자열이 카메라 부모/오브젝트 이름에 포함되면 우선 사용합니다. 예: XR Origin, XR_Root 등")]
    public string preferNameContains = "XR";

    [Tooltip("카메라가 늦게 생성될 수 있어 재시도합니다.")]
    public float retrySeconds = 0.5f;

    Canvas _canvas;

    void Awake()
    {
        _canvas = GetComponent<Canvas>();
    }

    void Start()
    {
        TryBind();
    }

    void TryBind()
    {
        if (_canvas.renderMode != RenderMode.WorldSpace) return;

        Camera cam = overrideCamera != null ? overrideCamera : FindBestCamera();

        if (cam != null)
        {
            _canvas.worldCamera = cam;
            // 필요하면 로그로 확인
            // Debug.Log($"[CanvasWorldCameraBinder] Bound worldCamera to: {cam.name}");
        }
        else
        {
            // 아직 카메라가 준비 안 됐으면 조금 뒤 재시도
            Invoke(nameof(TryBind), retrySeconds);
        }
    }

    Camera FindBestCamera()
    {
        // 1) 활성 카메라 중 이름에 preferNameContains가 포함된 카메라 우선
        var cams = Object.FindObjectsByType<Camera>(FindObjectsInactive.Include, FindObjectsSortMode.None);

        Camera fallback = null;

        foreach (var c in cams)
        {
            if (!c.isActiveAndEnabled) continue;
            if (c.targetTexture != null) continue; // 렌더텍스처용 카메라 제외(있을 때만)
            fallback ??= c;

            // 카메라 이름 또는 부모 이름에 "XR" 같은 문자열이 포함되면 우선 선택
            if (!string.IsNullOrEmpty(preferNameContains))
            {
                if (c.name.Contains(preferNameContains)) return c;
                if (c.transform.parent != null && c.transform.parent.name.Contains(preferNameContains)) return c;
                if (c.transform.root != null && c.transform.root.name.Contains(preferNameContains)) return c;
            }
        }

        // 2) 조건에 맞는 게 없으면 활성 카메라 아무거나
        return fallback;
    }
}