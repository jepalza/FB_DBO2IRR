

Type As ULong DWORD 
Type As UShort WORD 


' tipos almacenados en cada DBO
	Type sHeader field=1
		As String pszString 
		As DWORD dwVersion 
		As DWORD dwReserved1 
		As DWORD dwReserved2 
	End Type 

	Type sAnimationPos  field=1
		As DWORD times 
		As Single position(2) 
		As Single interpolation(2) 
	End Type 

	Type sAnimationRot  field=1
		As DWORD times 
		As Single rotation(3) 
	End Type 

	Type sAnimationScale  field=1
		As DWORD times 
		As Single scale(2) 
		As Single interpolation(2) 
	End Type 

	Type sAnimationMatrix  field=1
		As DWORD times 
		As Single matrix(3, 3) 
		As Single interpolation(3, 3) 
	End Type 

	Type sAnimationData  field=1
		As String names 
		As DWORD positionkeys 
		As sAnimationPos kPos 
		As DWORD rotationkeys 
		As sAnimationRot kRot 
		As DWORD scalekeys 
		As sAnimationScale kScale 
		As DWORD matrixkeys 
		As sAnimationMatrix kMatrix 
	End Type 

	Type sAnimation  field=1
		As String names 
		As DWORD length 
		As sAnimationData datas 
	End Type 

	Type sVertexData  field=1
		As Single x,y,z,nx,ny,nz,tu,tv,  ju,jv ' nota:JU y JV son mios, necesario para el formato DBO descubierto por mi
	 End Type 

	Type sMaterial  field=1
		As Single diffuse(3) 
		As Single ambient(3) 
		As Single specular(3) 
		As Single emissive(3) 
		As Single power 
	End Type 

	Type sMultipleMaterial  field=1
		As String names 
		As sMaterial mat 
		As DWORD start 
		As DWORD count 
		As DWORD polygons 
	End Type 

	Type sTexture  field=1
		As Ushort _tSize 
		As String names 
		As DWORD stage 
		As DWORD blendmode 
		As DWORD argument1 
		As DWORD argument2 
		As DWORD AddressU 
		As DWORD AddressV 
		As DWORD mag 
		As DWORD min 
		As DWORD mip 
		As DWORD TCMode 
		As DWORD PrimitiveStart 
		As DWORD PrimitiveCount 
	End Type 

	Type sBoneData  field=1
		As ushort _tSize 
		As String names 
		As DWORD NumInfluences 
		As DWORD VertexList 
		As Single WeightList 
		As Single tMatrix(3, 3) 
	End Type 


	dim shared as integer nelems=10000 ' alculos que con 10000 hay de sobra para vertices, y demas
	Type sMeshData  field=1
		As DWORD FVF 
		As DWORD FVFSize 
		As DWORD VertexCount
		As DWORD IndexCount 
		
		As sVertexData VertexData(nelems) ' suficientes? 
		As short IndexData(nelems) ' suficientes?  

		As DWORD pType 
		As DWORD DrawVertexCount 
		As DWORD DrawPrimitiveCount 

		'Mesh Vertex Declaration
		As DWORD BoneCount 
		As sBoneData bone 
		
		As bool bUseMaterial 
		As sMaterial mat 

		As DWORD TextureCount 
		As sTexture texture(nelems) ' suficientes? 
		
		As bool bWireframe 
		
		As bool bLight 

		As bool bCull 
		As bool bFog 
		As bool bAmbient 
		As bool bTransparency 
		As bool bGhost 
		As short GhostMode 
      
		'Mesh Linked ( internal – skip this block )
		'Mesh Sub Frames ( internal – skip this block )

		As String effectname 
		As DWORD AbitaryValue 
		As bool ZBiasFlag 
		As DWORD ZBiasSlope 
		As DWORD ZBiasDepth 
		As bool ZRead 
		As bool ZWrite 
		As DWORD AlphaTestValue 

		As bool bUseMultipleMaterials 
		As DWORD MaterialCount 
		As sMultipleMaterial mmaterial 

		As bool bVisible 
	End Type 




' ---------------------------------------
 ' creacion de grupos de entidades
	Type sFrame
		As String names 
		As Single matrix(3, 3) 
		As sMeshData ptr m 
		As sFrame ptr child 
		As sFrame ptr sibling 
		As Single offsets(2) 
		As Single rot(2) 
		As Single scale(2) 
		As bool bGood 
	End Type 
	
	Type objects
		As Ushort _cAnims, _cFrames 
		As sHeader head 
		As sFrame ptr root
		As sFrame ptr oFrame 
		redim As sAnimation anim(0)
	End Type 

