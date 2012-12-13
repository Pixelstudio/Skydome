using UnityEngine;
using System.Collections;

public class SkyTime : MonoBehaviour {

	public GameObject skydome;
	skydomeScript2 skydomeScript;
	public float dayLengthInMinutes;
	private float hourLength;
	private const float degPerHourOrig = 15;
	private double degPerHourNew;
	public bool progressJuilanDate = true;
	public bool enableTimeProgression = true;
	// Use this for initialization
	void Start () {
	//Length of an in-game hour eg. 1 = 2.5 2 = 5 (in seconds)
	hourLength = (dayLengthInMinutes * 60) / 24;
	//Number of degress roated per millisecond to get 360 in hourLength*24
	skydomeScript = skydome.GetComponent(typeof(skydomeScript2)) as skydomeScript2;
	}

    void OnEnable()
    {
	    skydomeScript = skydome.GetComponent(typeof(skydomeScript2)) as skydomeScript2;
	}
	// Update is called once per frame
	void Update () {
		degPerHourNew = (360/((Time.frameCount / Time.realtimeSinceStartup)*360*(hourLength)));
		if(enableTimeProgression == true)
		{
		if(skydomeScript.TIME < 23.9)
		{
		skydomeScript.TIME += (float)degPerHourNew;
		}
		else
		{
		skydomeScript.TIME=0;
			if(progressJuilanDate == true)
			{
				if( skydomeScript.JULIANDATE < 365)
				{
				skydomeScript.JULIANDATE += 1;
				}
				else
				{
				skydomeScript.JULIANDATE=1;
				}
			}
		}
		}
		
		
	
	}
}
