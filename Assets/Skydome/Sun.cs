using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class Sun : MonoBehaviour
{
	public GameObject skydome;
    skydomeScript2 skydomeScript;
	public Vector3 m_vDirection;
    public Vector3 m_vColor;
    Vector3 sunDirection = new Vector3();
    Vector3 sunDirection2 = new Vector3();
    float SolarAzimuth;
    float solarAltitude;
    Vector3 sunPosition;
    public float domeRadius;
    public float m_fTheta;
    public float m_fPhi;

    float LATITUDE_RADIANS;
    float STD_MERIDIAN;
    
    // Use this for initialization
    void Start()
    {
	    skydomeScript = skydome.GetComponent(typeof(skydomeScript2)) as skydomeScript2;
    }

    void OnEnable()
    {
	    skydomeScript = skydome.GetComponent(typeof(skydomeScript2)) as skydomeScript2;
    }

    void Update()
    {
        skydomeScript.LATITUDE = Mathf.Clamp(skydomeScript.LATITUDE, -90.0f, 90.0f);
        SetPosition(skydomeScript.TIME);
        transform.position = sunPosition;
    }
    void SetPosition(float fTheta, float fPhi )
    {
	    m_fTheta = fTheta;
	    m_fPhi = fPhi;

	    float fCosTheta = Mathf.Cos( m_fTheta );
        float fSinTheta = Mathf.Sin(m_fTheta);
        float fCosPhi = Mathf.Cos(m_fPhi);
        float fSinPhi = Mathf.Sin(m_fPhi);

	    m_vDirection = new Vector3( fSinTheta * fCosPhi,fCosTheta,fSinTheta * fSinPhi );
       // if (solarAltitude > -0.06f)
       // {
            float phiSun = (Mathf.PI * 2.0f) - SolarAzimuth;

            sunDirection.x = domeRadius;
            sunDirection.y = phiSun;
            sunDirection.z = solarAltitude;
            sunPosition = sphericalToCartesian(sunDirection);

            sunDirection2 = calcDirection(m_fTheta, phiSun);
            m_vDirection = Vector3.Normalize(m_vDirection);
            transform.LookAt(sunDirection2);
            ComputeAttenuation();
        //}
    }
    void SetPosition( float fTime )
    {
        LATITUDE_RADIANS = Mathf.Deg2Rad * skydomeScript.LATITUDE;
        STD_MERIDIAN = skydomeScript.MERIDIAN * 15.0f;

        float t = fTime + 0.170f * Mathf.Sin((4.0f * Mathf.PI * (skydomeScript.JULIANDATE - 80.0f)) / 373.0f)
                - 0.129f * Mathf.Sin((2.0f * Mathf.PI * (skydomeScript.JULIANDATE - 8.0f)) / 355.0f)
                + (STD_MERIDIAN - skydomeScript.LONGITUDE) / 15.0f;
        float fDelta = 0.4093f * Mathf.Sin((2.0f * Mathf.PI * (skydomeScript.JULIANDATE - 81.0f)) / 368.0f);

        float fSinLat = Mathf.Sin(LATITUDE_RADIANS);
        float fCosLat = Mathf.Cos(LATITUDE_RADIANS);
        float fSinDelta = Mathf.Sin(fDelta);
        float fCosDelta = Mathf.Cos(fDelta);
        float fSinT = Mathf.Sin((Mathf.PI * t) / 12.0f);
        float fCosT = Mathf.Cos((Mathf.PI * t) / 12.0f);

        solarAltitude = Mathf.Asin(fSinLat * fSinDelta - fCosLat * fCosDelta * fCosT);
        float fTheta = 0f;
        fTheta = Mathf.PI / 2.0f - solarAltitude;
        
        float opp = -fCosDelta * fSinT;
        float adj = -(fCosLat * fSinDelta+ fSinLat * fCosDelta * fCosT);
        SolarAzimuth = Mathf.Atan2(opp, adj);

	    float fPhi = Mathf.Atan( (- fCosDelta * fSinT) / ( fCosLat * fSinDelta - fSinLat * fCosDelta * fCosT ) );
        fPhi = -SolarAzimuth;
	    SetPosition( fTheta, fPhi );
    }
    Vector3 calcDirection(float thetaSun, float phiSun)
    {
        Vector3 dir = new Vector3();
        dir.x = Mathf.Cos(0.5f * Mathf.PI - thetaSun) * Mathf.Cos(phiSun);
        dir.y = Mathf.Sin(0.5f * Mathf.PI - thetaSun);
        dir.z = Mathf.Cos(0.5f * Mathf.PI - thetaSun) * Mathf.Sin(phiSun);
        return dir.normalized;
    }
    Vector3 sphericalToCartesian(Vector3 sunDir)
    {
        Vector3 res = new Vector3();
        res.y = sunDir.x * Mathf.Sin(sunDir.z);
        float tmp = sunDir.x * Mathf.Cos(sunDir.z);
        res.x = tmp * Mathf.Cos(sunDir.y);
        res.z = tmp * Mathf.Sin(sunDir.y);
        return res;
    }
    void ComputeAttenuation()
    {
        float fBeta = 0.04608365822050f * skydomeScript.m_fTurbidity - 0.04586025928522f;
        float fTauR, fTauA;
        float[] fTau = new float[3];
        float tmp = 93.885f - (m_fTheta / Mathf.PI * 180.0f);
        
        float m;
        m = (float)(1.0f / (Mathf.Cos(m_fTheta) + 0.15f * tmp));  // Relative Optical Mass
        //m = (float)(1.0f / (Mathf.Cos(m_fTheta) + 0.15f * Mathf.Pow(93.885f - m_fTheta / Mathf.PI * 180.0f, -1.253f)));
        if (m < 0)
        {
            m = 20;
        }
        float[] fLambda = new float[3]; 
	    fLambda[0] = 0.65f;	// red (in um.)
	    fLambda[1] = 0.57f;	// green (in um.)
	    fLambda[2] = 0.475f;	// blue (in um.)
        for(int i = 0; i < 3; i++)
	    {
		    // Rayleigh Scattering
		    // Results agree with the graph (pg 115, MI) */
		    // lambda in um.
            fTauR = Mathf.Exp(-m * 0.008735f * Mathf.Pow(fLambda[i], -4.08f));

		    // Aerosal (water + dust) attenuation
		    // beta - amount of aerosols present 
		    // alpha - ratio of small to large particle sizes. (0:4,usually 1.3)
		    // Results agree with the graph (pg 121, MI) 
		    const float fAlpha = 1.3f;
            fTauA = Mathf.Exp(-m * fBeta * Mathf.Pow(fLambda[i], -fAlpha));  // lambda should be in um
		    fTau[i] = fTauR * fTauA;
        }

        m_vColor = new Vector3(fTau[0], fTau[1], fTau[2]);
        light.color = new Color(fTau[0], fTau[1], fTau[2]);
    }
}
