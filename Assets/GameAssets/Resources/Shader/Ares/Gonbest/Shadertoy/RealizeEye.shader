﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Gonbest/Shadertoy/RealizeEye" 
{ 
    Properties{      
		//iMouse ("Mouse Pos", Vector) = (100, 100, 0, 0)  
        iChannel0("iChannel0", 2D) = "white" {}  
		iChannel3("iChannel3",2D) = "white"{}
        iChannelResolution0 ("iChannelResolution0", Vector) = (100, 100, 0, 0)
    }
 
    CGINCLUDE    
    #include "UnityCG.cginc"   
	#include "../Include/Base/MathCG.cginc"
    #pragma target 3.0      
 
    #define vec2 float2
    #define vec3 float3
    #define vec4 float4
	#define tvec2(x) (float2)x	
    #define tvec3(x) (float3)x	
    #define tvec4(x) (float4)x	
    #define mat2 float2x2
    #define mat3 float3x3
    #define mat4 float4x4
    #define iTime _Time.y
    #define mod fmod
    #define mix lerp
    #define fract frac
    #define texture2D tex2D
    #define iResolution _ScreenParams
    #define gl_FragCoord ((_iParam.scrPos.xy/_iParam.scrPos.w) * _ScreenParams.xy)
 
    #define PI2 6.28318530718
    #define pi 3.14159265358979
    #define halfpi (pi * 0.5)
    #define oneoverpi (1.0 / pi)
 
    fixed4 iMouse;
    sampler2D iChannel0;
	sampler2D iChannel3;
    fixed4 iChannelResolution0;
 
    struct v2f {    
        float4 pos : SV_POSITION;    
		float2 uv :TEXCOORD1;
        float4 scrPos : TEXCOORD0;   
    };              
 
    v2f vert(appdata_base v) {  
        v2f o;
        o.pos = UnityObjectToClipPos (v.vertex);
		o.uv = v.texcoord.xy;
        o.scrPos = ComputeScreenPos(o.pos);
        return o;
    }  
 
     void mainImage( out vec4 fragColor, in vec2 fragCoord );


    fixed4 frag(v2f _iParam) : COLOR0 { 
        vec2 fragCoord = _iParam.uv *iResolution.xy;//gl_FragCoord;
        vec4 fColor = vec4(0,0,0,0);
        mainImage(fColor,fragCoord);
        return fColor;
    }  

 
   // Hazel Quantock - 15/08/2013

	/*
	Eye ball effects:
	- Ray-marched shape
	- Ray-traced iris refraction
	- Fake photon mapping on iris
	- Subsurface scattering on sclera
	- HDR reflections with fresnel
	- Eyelid reflection occlusion
	- Eyelid ambient occlusion
	- Procedural textures
	- Procedural animation
	*/

	// KEY CONTROLS - (click on eye to give keyboard focus)
	#define Key_M  77 
	// mouse controls camera / eye direction

	#define  Key_E  69 
	// refraction on/off
	#define  Key_P  80 
	// photon mapping on/off
	#define  Key_L  76 
	// change photon mapping technique (both fake, but one is imitating reality and the other is prettier)

	#define  Key_S  83 
	// subsurface scattering on/off
	#define  Key_A  65 
	// ambient occlusion on/off

	#define  Key_R  82 
	// reflection on/off
	#define  Key_O  79 
	// reflection eyelid occlusion on/off

	#define  Key_C  67 
	// iris colour
	#define  Key_N  78 
	// iris normal


				

	// Lights
	#if (1)
		// High-contrast light edge-on
		#define lightDir vec3(-2,2,.5)
		#define lightColour  tvec3(1.0)
		#define fillLightDir  vec3(0,1,0)
		#define fillLightColour  vec3(.65,.7,.8)*.7//vec3(.15,.2,.25);
	#else
		// more neutral "good" lighting (doesn't show off the effects)
		#define lightDir  vec3(-2,2,-1)
		#define lightColour  vec3(.83,.8,.78)
		#define fillLightDir  vec3(0,1,0)
		#define fillLightColour  vec3(.65,.7,.8)
	#endif



	// Constants
	#define DPI  6.28318530717958647692

	// Forward declarations
	float Noise( in vec3 x );
	vec2 Noise2( in vec3 x );



	// Gamma correction
	#define GAMMA (2.2)

	vec3 ToLinear( in vec3 col )
	{
		// simulate a monitor, converting colour values into light values
		return pow( col, tvec3(GAMMA) );
	}

	vec3 ToGamma( in vec3 col )
	{
		// convert back into colour values, so the correct light will come out of the monitor
		return pow( col, tvec3(1.0/GAMMA) );
	}


	// key is javascript keycode: http://www.webonweboff.com/tips/js/event_key_codes.aspx
	bool ReadKey( int key, bool toggle )
	{
		float keyVal = tex2D( iChannel3, vec2( (float(key)+.5)/256.0, toggle?.75:.25 ) ).x;
		return false;//(keyVal>.5)?true:false;
	}


	// ------- EDIT THESE THINGS! -------

	// Camera (also rotated by mouse)
	#define CamPos  vec3(0,0,-250.0)
	#define CamLook  vec3(0,0,0)
	#define CamZoom  10.0
	 // actually not needed
	#define NearPlane  0.0
	#define drawDistance  1000.0

	//fillLightColour*.5;//vec3(.1,.3,.5);
	#define SkyColour  vec3(.4,.25,.2)

	vec3 SkyDome( vec3 rd )
	{
		//the cube maps have lines in, and aren't HDR, so make our own shapes
		
		// random variation
		vec3 result = ToLinear(SkyColour)*2.0*Noise(rd);
		
		// square sky-light
		result = mix( result, tvec3(8), smoothstep(.8,1.0,rd.y/max((rd.x+1.0),abs(rd.z))) );

		return result;
	}

	// Eye params
	#define  IrisAng  6.28318530717958647692/12.0
	#define  PupilAng  (1.6*(6.28318530717958647692/12.0)/5.0)
	#define  EyeRadius  10.0
	// used for photon trace, must be bigger than EyeRadius*sin(IrisAng)
	#define  BulgeRadius  6.0 


	vec4 ComputeEyeRotation()
	{
		vec2 rot;
		if ( !ReadKey( Key_M, true ) && iMouse.w > .00001 )
			rot = .25*vec2(1.0,1.0)*DPI*(iMouse.xy-iResolution.xy*.5)/iResolution.x;
		else
		{
			float time = iTime/2.0;
			time += Noise(vec3(0,time,0)); // add noise to time (this adds SO MUCH character!)
			float flick = floor(time)+smoothstep(0.0,0.05,fract(time));
			rot = vec2(.2,.1)*DPI*(tex2Dproj( iChannel0, vec4((flick+.5)/256.0, .5, -100.0,1) ).rb-.5);
		}
		
		return vec4(cos(rot.x),sin(rot.x),cos(rot.y),sin(rot.y));
	}


	vec3 ApplyEyeRotation( vec3 pos, vec4 rotation )
	{
		pos.yz = rotation.z*pos.yz + rotation.w*pos.zy*vec2(1,-1);
		pos.xz = rotation.x*pos.xz + rotation.y*pos.zx*vec2(1,-1);
		
		return pos;
	}
		


	// Shape
	// This should return continuous positive values when outside and negative values inside,
	// which roughly indicate the distance of the nearest surface.
	float Isosurface( vec3 pos, vec4 eyeRotation )
	{
		pos = ApplyEyeRotation(pos,eyeRotation);
		
	/*	float f = length(pos)-EyeRadius;
		
	//	f += Noise(pos*3.0)*.008;

		// cornea bulge
		float o = EyeRadius*cos(IrisAng)-sqrt(BulgeRadius*BulgeRadius-EyeRadius*EyeRadius*pow(sin(IrisAng),2.0));
		float g = length(pos-vec3(0,0,-o))-BulgeRadius;

	//g += Noise(pos/2.0)*.5;

		return min(f,g);
		//return -log(exp(-g*2.0)+exp(-f*2.0))/2.0;*/
		
		vec2 slice = vec2(length(pos.xy),pos.z);
		
		float aa = atan2(slice.x,slice.y);
		float bulge = cos(DPI*.2*aa/IrisAng);
		bulge = bulge*.8-.8;
		bulge *= smoothstep(DPI*.25,0.0,aa);
		
		// sharp-edged bulge
	//	if ( aa < IrisAng )
	//		bulge += cos(DPI*.25*aa/IrisAng)*.5;
		bulge += cos(DPI*.25*aa/IrisAng)*.5 * smoothstep(-.02,.1,IrisAng-aa); // slightly softer
		
		return length(slice) - EyeRadius - bulge;
	}



	float GetEyelidMask( vec3 pos, vec4 eyeRotation )
	{
		vec3 eyelidPos = pos;
		float eyelidTilt = -.05;
		eyelidPos.xy = cos(eyelidTilt)*pos.xy + sin(eyelidTilt)*pos.yx*vec2(1,-1);
		
		float highLid = tan(max(DPI*.05,asin(eyeRotation.w)+IrisAng+.05));
		float lowLid = tan(DPI*.1);
		
		float blink = smoothstep(.0,.02,abs(Noise(vec3(iTime*.2,0,0))-.5 ));
		highLid *= blink;
		lowLid *= blink;
		
		return min(
					(-eyelidPos.z-2.0) - (-eyelidPos.y/lowLid),
					(-eyelidPos.z-2.0) - (eyelidPos.y/highLid)
				);
	}
		
	float GetIrisPattern( vec2 uv )
	{
		return Noise( vec3( 10.0*uv/pow(length(uv),.7), 0 ) );
	}

	// Colour
	vec3 Shading( vec3 worldPos, vec3 norm, float shadow, vec3 rd, vec4 eyeRotation )
	{
		vec3 view = GBNormalizeSafe(-rd);

		

		// eyelids - just match BG colour
		float eyelidMask = GetEyelidMask(worldPos, eyeRotation);
		
		/*
		if ( eyelidMask < 0.0 || (-worldPos.z-3.0) < (worldPos.x/tan(DPI*.23)) )
		{
			return ToLinear(SkyColour);
		}
	*/
		
		vec3 pos = ApplyEyeRotation(worldPos,eyeRotation);
		
		float lenposxy = length(pos.xy);
		float ang = atan(lenposxy/(-pos.z));
		if ( ang < 0.0 )
			ang += DPI/2.0;
		

		// refract ray
		vec3 irisRay = ApplyEyeRotation(-view,eyeRotation);
		vec3 localNorm = ApplyEyeRotation(norm,eyeRotation);
		float a = dot(irisRay,localNorm);
		float b = cos(acos(a)*1.33);
		//if ( !ReadKey( Key_E, true ) )
			irisRay += localNorm*(b-a);
		irisRay = GBNormalizeSafe(irisRay);
		
		// intersect with plane
		float planeDist = -cos(IrisAng)*EyeRadius;
		float t = (planeDist-pos.z)/irisRay.z;

		vec3 ppos = t*irisRay+pos;

		

		// polar coord map
		float rad = length(ppos.xy);
		float pupilr = EyeRadius*sin(PupilAng);
		float irisr = EyeRadius*sin(IrisAng);
		
		//图案
		float irisPattern = GetIrisPattern(ppos.xy); // reduce contrast of this now we have actual lighting!

	/*	vec3 iris = mix( mix( vec3(.3,.1,.1)*.5+.5*vec3(.6,.4,.1), vec3(.6,.4,.1), irisPattern ), // hazel
						mix( vec3(.2,.2,.2)*.5+.5*vec3(.5,.45,.2), vec3(.5,.45,.2), irisPattern ),*/

	/*	vec3 iris = mix( mix( vec3(.1,.1,.4), vec3(.7,.9,1), irisPattern ), // blue
						mix( vec3(.1,.1,.4), vec3(.3,.4,.7), irisPattern ),*/

	//					smoothstep(pupilr*2.0,irisr,rad));
		//虹膜
		vec3 iris = ToLinear( mix( pow( vec3(.65,.82,.85), 2.0*tvec3(1.2-sqrt(irisPattern)) ),
						vec3(1,.5,.2), .7*pow( mix( smoothstep(pupilr,irisr,rad), Noise(ppos), .7), 2.0) ));
		

		if ( ReadKey( Key_C, true ) )
			iris = tvec3(1);

		// darken outer
		iris *= pow( smoothstep( irisr+1.0, irisr-1.5, rad ), GAMMA );

		

		vec3 irisNorm;
		irisNorm.x = GetIrisPattern(ppos.xy+vec2(-.001,0)) - GetIrisPattern(ppos.xy+vec2(.001,0));
		irisNorm.y = GetIrisPattern(ppos.xy+vec2(0,-.001)) - GetIrisPattern(ppos.xy+vec2(0,.001));

		// add a radial lump
		irisNorm.xy += -.01*GBNormalizeSafe(ppos.xy)*sin(1.*DPI*rad/irisr);

		irisNorm.z = -.15; // adjust severity of bumps
		irisNorm = GBNormalizeSafe(irisNorm);
		

		if ( ReadKey( Key_N, true ) )
			irisNorm = vec3(0,0,-1);
			

		// lighting
		// fake photon mapping by crudely sampling the photon density

		// apply lighting with this modified normal
		vec3 lightDirN = GBNormalizeSafe(lightDir);
		vec3 localLightDir = ApplyEyeRotation(lightDirN,eyeRotation);

		vec3 fillLightDirN = GBNormalizeSafe(fillLightDir);
		vec3 localFillLightDir = ApplyEyeRotation(fillLightDirN,eyeRotation);

		// Bend the light, imitating results of offline photon-mapping
		// Jimenez's paper makes this seem very complex, because their mapping used a non-flat receiver
		// but the self-shadowing was negligible, so the main effect was just like premultiplying by a normal
		// where we'd get better results by using the actual normal.

		float photonsL, photonsFL;

		if ( !ReadKey( Key_P, true ) )
		{
			if ( !ReadKey( Key_L, true ) )
			{
				// Nice retro-reflective effect, but not correct
				vec3 nn = GBNormalizeSafe(vec3( ppos.xy, -sqrt(max(0.0,BulgeRadius*BulgeRadius-rad*rad)) ));
				
				vec3 irisLDir = localLightDir;
				vec3 irisFLDir = localFillLightDir;
			//	irisLDir.z = -cos(acos(-irisLDir.z)/1.33); // experiments showed it cuts out at 120 degrees, i.e. 1.33*the usual 90 degree cutoff
			//	irisFLDir.z = -cos(acos(-irisFLDir.z)/1.33); // experiments showed it cuts out at 120 degrees, i.e. 1.33*the usual 90 degree cutoff
				float d = dot(nn,irisLDir);
				irisLDir += nn*(cos(acos(d)/1.33) - d);
				d = dot(nn,irisFLDir);
				irisFLDir += nn*(cos(acos(d)/1.33) - d);
				irisLDir = GBNormalizeSafe(irisLDir);
				irisFLDir = GBNormalizeSafe(irisFLDir);
				photonsL = smoothstep(0.0,1.0,dot(irisNorm,irisLDir)); //soften terminator
				photonsFL = (dot(irisNorm,irisFLDir)*.5+.5);
				
				//Seriously, this^ looks really nice, but not like reality. Bah!
			
			/* reverse it, to make it look a lot like the accurate version - meh
				vec3 nn = GBNormalizeSafe(vec3( -ppos.xy, -sqrt(max(0.0,BulgeRadius*BulgeRadius-rad*rad)) ));
				
				vec3 irisLDir = localLightDir;
				vec3 irisFLDir = localFillLightDir;
				float d = dot(nn,irisLDir);
				irisLDir += nn*(cos(acos(d)/1.33) - d);
				d = dot(nn,irisFLDir);
				irisFLDir += nn*(cos(acos(d)/1.33) - d);
				irisLDir = GBNormalizeSafe(irisLDir);
				irisFLDir = GBNormalizeSafe(irisFLDir);
				
				float photonsL = smoothstep(0.0,1.0,dot(irisNorm,irisLDir)); // soften the terminator
				float photonsFL = (dot(irisNorm,irisFLDir)*.5+.5);
			*/
				//return photonsL;
			}
			else
			{
				//this is a reasonable match to the dark crescent effect seen in photos and offline photon mapping, but it looks wrong to me.
				vec3 irisLDir = localLightDir;
				vec3 irisFLDir = localFillLightDir;
				irisLDir.z = -cos(acos(-irisLDir.z)/1.5); // experiments showed it cuts out at 120 degrees, i.e. 1.33*the usual 90 degree cutoff
				irisFLDir.z = -cos(acos(-irisFLDir.z)/1.5); // experiments showed it cuts out at 120 degrees, i.e. 1.33*the usual 90 degree cutoff
				irisLDir = GBNormalizeSafe(irisLDir);
				irisFLDir = GBNormalizeSafe(irisFLDir);
			
				photonsL = smoothstep(0.0,1.0,dot(irisNorm,irisLDir)); // soften the terminator
				photonsFL = (dot(irisNorm,irisFLDir)*.5+.5);
			
				// dark caustic ring
				photonsL *= .3+.7*smoothstep( 1.2, .9, length(ppos.xy/irisr+.2*irisLDir.xy/(irisLDir.z-.05)) );
			//	photonsFL *= ...;
			
			}
			
		}
		else
		{
			// no photons --没有光量子效果
			photonsL = max( 0.0, dot(irisNorm,localLightDir) ); 
			photonsFL = .5+.5*dot(irisNorm,localLightDir); 
			
		}
		
		
		vec3 l = ToLinear(lightColour)*photonsL;
		vec3 fl = ToLinear(fillLightColour)*photonsFL;

		vec3 ambientOcclusion = tvec3(1);
		vec3 eyelidShadow = tvec3(1);
		if ( !ReadKey( Key_A, true ) )
		{
			// ambient occlusion on fill light
			ambientOcclusion = mix( tvec3(1), ToLinear(vec3(.8,.7,.68)), pow(smoothstep( 5.0, 0.0, eyelidMask ),1.0) );
			
			// shadow on actual light
			eyelidShadow = mix( tvec3(1), ToLinear(vec3(.8,.7,.68)), smoothstep( 2.0, -2.0, GetEyelidMask( worldPos+lightDir*1.0, eyeRotation ) ) );
		}
		fl *= ambientOcclusion;
		l *= eyelidShadow;		
		
		iris *= l+fl;
		

		// darken pupil 黑色瞳孔
		iris *= smoothstep( pupilr-.01, pupilr+.5, rad );


		// veins 静脉血管
		float theta = atan2(pos.x,pos.y);		
		theta += Noise(pos*1.0)*DPI*.03;
		float veins = (sin(theta*60.0)*.5+.5);
		
		veins *= veins;
		veins *= (sin(theta*13.0)*.5+.5);		

		veins *= smoothstep( IrisAng, DPI*.2, ang );
		
		veins *= veins;
		veins *= .5;
		
		
		//巩膜
		vec3 sclera = mix( ToLinear(vec3(1,.98,.96)), ToLinear(vec3(.9,.1,0)), veins );

		float ndotl = dot(norm,lightDirN);
		
		// subsurface scattering
	//	float subsurface = max(0.0,-2.0*ndotl*EyeRadius);
	//	l = pow(ToLinear(vec3(.5,.3,.25)),vec3(subsurface*.2)); // more intense the further light had to travel

		// fake, because that^ approximation gives a hard terminator
		l = pow(ToLinear(vec3(.5,.3,.25)), tvec3(mix( 3.0, 0.0, smoothstep(-1.0,.2,ndotl) )) );
		
		if ( ReadKey( Key_S, true ) )
	//		l = mix( l, vec3(max(0.0,ndotl)), 0.5 );
	//	else
			l = tvec3(max(0.0,ndotl));

		l *= ToLinear(lightColour);
		
		fl = ToLinear(fillLightColour)*(dot(norm,fillLightDirN)*.5+.5);

		fl *= ambientOcclusion;
		l *= eyelidShadow;		
		
		
		sclera *= l+fl;

		// blend between them
		float blend = smoothstep(-.1,.1,ang-IrisAng);
		vec3 result = mix(iris,sclera,blend);

		
		// eyelid ambient occlusion/radiosity
	//	if ( !ReadKey( Key_A, true ) )
			//result *= mix( vec3(1), ToLinear(vec3(.65,.55,.55)), exp2(-eyelidMask*2.0) );
	//		result *= mix( vec3(1), ToLinear(vec3(.8,.7,.68)), pow(smoothstep( 5.0, 0.0, eyelidMask ),1.0) );
		
		
		// bumps - in specular only to help sub-surface scattering look smooth
		vec3 bumps;
		bumps.xy = .7*Noise2( pos*3.0 );
		bumps.z = sqrt(1.0-dot(bumps.xy,bumps.xy));

		bumps = mix( vec3(0,0,1), bumps, blend );
		
		norm.xy += bumps.xy*.1;
		norm = GBNormalizeSafe(norm);
		
		float glossiness = mix(.7,1.0,bumps.z);
		
		// reflection map
		float ndoti = dot( view, norm );
		vec3 rr = -view+2.0*ndoti*norm;
		vec3 reflection = SkyDome( rr );
		
		// specular
		vec3 h = GBNormalizeSafe(view+lightDir);
		float specular = pow(max(0.0,dot(h,norm)),2000.0);

		// should fresnel affect specular? or should it just be added?
		reflection += specular*32.0*glossiness*ToLinear(lightColour);

		// reflection of eyelids
		//float eyelidReflection = smoothstep( 1.8, 2.0, eyelidMask );
		// apply some parallax (subtle improvement when looking up/down at eye)
		float eyelidReflection = smoothstep( .8, 1.0, GetEyelidMask( GBNormalizeSafe(worldPos + rd*2.0)*EyeRadius, eyeRotation ) );
		if ( !ReadKey( Key_O, true ) )
			reflection *= eyelidReflection;

		// fresnel
		float fresnel = mix(.04*glossiness,1.0,pow(1.0-ndoti,5.0));

		
		if ( !ReadKey( Key_R, true ) )
			result = mix ( result, reflection, fresnel );
		

		//anti-alias the edge
		float mask2 = min( eyelidMask, (-worldPos.z-3.0) - (worldPos.x/tan(DPI*.23)) );
		//result = mix( ToLinear(SkyColour), result, smoothstep(.0,.3,mask2) );
		
		return result;// result;
	}


	// Precision controls
	#define epsilon  .003
	#define  normalPrecision  .1
	#define  shadowOffset  .1
	// takes time
	#define  traceDepth  100



	// ------- BACK-END CODE -------

	vec2 Noise2( in vec3 x )
	{
		vec3 p = floor(x.xzy);
		vec3 f = fract(x.xzy);
		f = f*f*(3.0-2.0*f);
	//	vec3 f2 = f*f; f = f*f2*(10.0-15.0*f+6.0*f2);

		vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
		vec4 rg = tex2Dlod( iChannel0, vec4((uv+0.5)/256.0, 0.0,0 ));
		return mix( rg.yw, rg.xz, f.z );
	}
			
	float Noise( in vec3 x )
	{
		return Noise2(x).x;
	}

	float Trace( vec3 ro, vec3 rd, vec4 eyeRotation )
	{
		float t = 0.0;
		float dist = 1.0;
		for ( int i=0; i < traceDepth; i++ )
		{
			if ( abs(dist) < epsilon || t > drawDistance || t < 0.0 )
				continue;
			dist = Isosurface( ro+rd*t, eyeRotation );
			t = t+dist;
		}
		
		return t;//vec4(ro+rd*t,dist);
	}

	// get normal
	vec3 GetNormal( vec3 pos, vec4 eyeRotation )
	{
		const vec2 delta = vec2(normalPrecision, 0);
		
		vec3 n;

	// it's important this is centred on the pos, it fixes a lot of errors
		n.x = Isosurface( pos + delta.xyy, eyeRotation ) - Isosurface( pos - delta.xyy, eyeRotation );
		n.y = Isosurface( pos + delta.yxy, eyeRotation ) - Isosurface( pos - delta.yxy, eyeRotation );
		n.z = Isosurface( pos + delta.yyx, eyeRotation ) - Isosurface( pos - delta.yyx, eyeRotation );
		return GBNormalizeSafe(n);
	}				

	// camera function by TekF
	// compute ray from camera parameters
	vec3 GetRay( vec3 dir, float zoom, vec2 uv )
	{
		uv = uv - .5;
		uv.x *= iResolution.x/iResolution.y;
		
		dir = zoom*GBNormalizeSafe(dir);
		vec3 right = GBNormalizeSafe(cross(vec3(0,1,0),dir));
		vec3 up = GBNormalizeSafe(cross(dir,right));
		
		return dir + right*uv.x + up*uv.y;
	}

	void mainImage( out vec4 fragColor, in vec2 fragCoord )
	{
		vec2 uv = fragCoord.xy / iResolution.xy;

		vec3 camPos = CamPos;
		vec3 camLook = CamLook;

		
		vec2 camRot = .5*DPI*(iMouse.xy-iResolution.xy*.5)/iResolution.x;
		if ( !ReadKey( Key_M, true ) )
			camRot = vec2(0,0);
		camPos.yz = cos(camRot.y)*camPos.yz + sin(camRot.y)*camPos.zy*vec2(1,-1);
		camPos.xz = cos(camRot.x)*camPos.xz + sin(camRot.x)*camPos.zx*vec2(1,-1);
		
		vec4 eyeRotation = ComputeEyeRotation();
		
		
		if ( Isosurface(camPos, eyeRotation) <= 0.0 )
		{
			// camera inside ground
			fragColor = vec4(0,0,0,0);
			return;
		}
		
		vec3 ro = camPos;
		vec3 rd;
		rd = GetRay( camLook-camPos, CamZoom, uv );
		
		ro += rd*(NearPlane/CamZoom);
		
		rd = GBNormalizeSafe(rd);
		
		float t = Trace(ro,rd,eyeRotation);

		vec3 result = ToLinear(SkyColour);

		
		//if ( t > 0.0 && t < drawDistance )
		{
			vec3 pos = ro+t*rd;
				
			vec3 norm = GetNormal(pos,eyeRotation);
			
			// shadow test
			float shadow = 1.0;
			//if ( Trace( pos+lightDir*shadowOffset, lightDir, eyeRotation ) < drawDistance )
			//	shadow = 0.0;
			
			result = Shading( pos, norm, shadow, rd, eyeRotation );
			
			// fog
			//result = mix ( SkyColour, result, exp(-t*t*.0002) );
		}
		fragColor = vec4( ToGamma( result ), 1.0 );
	}
 
    ENDCG    
 
    SubShader {    
        Pass {    
            CGPROGRAM    
 
            #pragma vertex vert    
            #pragma fragment frag    
            #pragma fragmentoption ARB_precision_hint_fastest     
 
            ENDCG    
        }    
    }     
    FallBack Off    
}