' basado en los fuentes de -> https://github.com/Red--Eye/.dbo-converter
' he convertido a FreeBasic los fuentes, y mejorado (en lo posible) para adaptarlo a "tiempos modernos"
' puede convertir un DBO en formato IRRMESH (mallas estáticas del IRRLICHT)

#Undef BOOL
#Define BOOL UByte

#Undef TRUE
#Define TRUE 1

#Undef FALSE
#Define FALSE 0

#include "CDBOConv.bi"

declare sub create()
declare sub getAnimationData()
declare sub getAnimation()
declare Sub getFrame()

declare Function getBoneData() as sBoneData
declare Function getTextureData() as sTexture
declare Function getMaterial() As sMaterial 
declare Function getMMaterial() As sMultipleMaterial

declare sub getMesh( m As sMeshData Ptr)
declare Sub readDATA(size As UInteger)  

declare Function readSTRING(size As UInteger) As String 
declare Function readFLOAT() As Single 
declare Function readINTEGER() As Integer  
declare Function readDWORD() As DWORD  
declare Function readWORD() As WORD  
declare Function readBOOL() As bool   

' ------------------------- IRR ---------------------------
declare Sub irr_saveto() 
declare Function irr_ready() As bool 
declare Function irr_getBufferCount() As UInteger
declare sub irr_init() 
declare Sub irr_setMeshVersion(_namespace As String , version As String) 
declare Sub irr_setBoundingBox(mins() As Single , maxs() As Single) 
declare Sub irr_addEnd(tag As String)          
declare Sub irr_addBuffer(nobj as integer)

dim shared as objects ptr obj

dim shared as integer objetos(10000) ' punteros a cada objeto sacado del mapa 
dim shared AS INTEGER NumOBJ=0 ' numero de vertices localizados

dim shared as string ficheroDBO
dim shared as integer a,b,c ' comunes de ayuda

'-----------------------------------------------
' mis adaptaciones y mejoras

function comillas() as string
	return chr(34)
end function

function fmt6(n as single) as string
	n=fix(n*10000)/10000
	dim as string sa,sb
	dim as integer a
	sa=" "+str(n)
	if instr(sa,"e") then print "error en un valor '1e+...', revisar salida"
	a=instr(sa,".")
	if a=0 then 
		sa=sa+".000000"
	else
		sb=mid(sa,a+1)
		sa=left(sa,a)
		sb=sb+"000000"
		sa=sa+left(sb,6)
	endif
	return sa
end function
'--------------------------------------------------



Sub create() 
	Print "* loading object *" 

	obj = new objects() 

	'Header Information
	obj->head.pszString   = readSTRING(readDWORD()) 
	obj->head.dwVersion   = readDWORD() 
	obj->head.dwReserved1 = readDWORD() 
	obj->head.dwReserved2 = readDWORD() 

	Print "> header info version = " ; obj->head.dwVersion 

	'Data Blocks
	Print "> reading data blocks" 
	dim as DWORD dwCode = readDWORD() 
	Dim As Integer dwCodeSize = readDWORD() 
	while(dwCode > 0)
		Select Case (dwCode)
			case 1  'root
            obj->root = new sFrame() 
            obj->oFrame = obj->root
            getFrame() 

         case 2 
            obj->_cAnims+=1
            redim obj->anim(obj->_cAnims) 
            getAnimation() 

         case 406 
            readDATA(dwCodeSize) 

         case 0 
            Print "* unkown error occured, file corrupted *" 
            readDATA(dwCodeSize) 

         case else 
            Print "* unkown data, skipping data *" 
            readDATA(dwCodeSize) 
		
      End Select

		dwCode = readDWORD() 
		dwCodeSize = readDWORD() 
	
   Wend
    
	Print " > extra info: anim count: " ; ubound(obj->anim) ; " frame count: " ; obj->_cFrames 
End Sub

Sub getAnimationData() 
	Print "  > reading one animation data" 
	dim as DWORD dwCode = readDWORD() 
	Dim As Integer dwCodeSize = readDWORD() 
	if (dwCode = 0) Then 
		readDATA(dwCodeSize)  
	EndIf
  
	dim as sAnimationData _data 
	while(dwCode > 0)  
		Select Case (dwCode)
         case 211 
            _data.names = readSTRING(readDWORD()) 

         case 212 
            _data.positionkeys = readDWORD() 

			case 213
				if _data.positionkeys>0 then
					for p As UInteger =0 To _data.positionkeys -1        
						dim as sAnimationPos pos_ 
						pos_.times = readDWORD() 
						pos_.position(0) = readFLOAT() 
						pos_.position(1) = readFLOAT() 
						pos_.position(2) = readFLOAT() 
						pos_.interpolation(0) = readFLOAT() 
						pos_.interpolation(1) = readFLOAT() 
						pos_.interpolation(2) = readFLOAT() 
						_data.kPos=pos_
					Next
				endif

         case 214 
            _data.rotationkeys = readDWORD() 

			case 215
				if _data.rotationkeys>0 then
					for r As UInteger =0 To _data.rotationkeys-1         
						dim as sAnimationRot rot 
						rot.times = readDWORD() 
						rot.rotation(0) = readFLOAT() 
						rot.rotation(1) = readFLOAT() 
						rot.rotation(2) = readFLOAT() 
						_data.kRot=rot
					Next
				endif

         case 216
            _data.scalekeys = readDWORD() 

			case 217
				if _data.scalekeys>0 then
					for s As UInteger =0 To _data.scalekeys-1        
						dim as sAnimationScale scale 
						scale.times = readDWORD() 
						scale.scale(0) = readFLOAT() 
						scale.scale(1) = readFLOAT() 
						scale.scale(2) = readFLOAT() 
						_data.kScale=scale
					Next
				endif

         case 218  
            _data.matrixkeys = readDWORD() 

			case 219
				if _data.matrixkeys>0 then
					for m As UInteger =0 To _data.matrixkeys-1         
						dim as sAnimationMatrix matrix 
						matrix.times = readDWORD() 
						for x As Integer =0 To 3        
							for y As Integer =0 To 3        
								matrix.matrix(x, y) = readFLOAT() 
							Next
						Next
						for x As Integer =0 To 3        
							for y As Integer =0 To 3        
								matrix.interpolation(x, y) = readFLOAT() 
							Next
						Next
						_data.kMatrix=matrix
					Next
				endif

         case 220 
            obj->anim(obj->_cAnims-1).datas=_data
            getAnimationData() 

         case else  
            readDATA(dwCodeSize) 
		
     End Select

		dwCode = readDWORD() 
		dwCodeSize = readDWORD() 
	
  Wend
    
End Sub

Sub getAnimation() 
	Print " > reading animation " 
	dim as DWORD dwCode = readDWORD() 
	Dim As Integer dwCodeSize = readDWORD()
	
	if(dwCode = 0) Then 
      readDATA(dwCodeSize)  
   EndIf

	while(dwCode > 0)  

		Select Case (dwCode)
         case 201 
            obj->anim(obj->_cAnims-1).names = readSTRING(readDWORD()) 

         case 202 
            obj->anim(obj->_cAnims-1).length = readDWORD() 

         case 203 
            getAnimationData() 
      End Select
		dwCode = readDWORD() 
		dwCodeSize = readDWORD() 
   Wend
    
End Sub

Function getBoneData() As sBoneData 
	Print "   > reading a bone" 
	dim as sBoneData bone
   bone._tSize = 8 
	dim as DWORD dwCode = readDWORD() 
	Dim As Integer dwCodeSize = readDWORD() 

	while(dwCode > 0)  
		Select Case (dwCode)  
		case 301
			bone.names = readSTRING(readDWORD()) 

		case 302
			bone.NumInfluences = readDWORD() 

		case 303
			if bone.NumInfluences>0 then
				for n As UInteger=0 To bone.NumInfluences -1        
					bone.VertexList=readDWORD()
				Next
			endif
         
		case 304
			if bone.NumInfluences>0 then
				for n As UInteger=0 To bone.NumInfluences -1         
					bone.WeightList=readFLOAT()
				Next
			endif

		case 305 
			for x As Integer =0 To 3       
				for y As Integer =0 To 3        
					bone.tMatrix(x, y) = csng(readDWORD()) 
            Next
         Next
		
     End Select

		bone._tSize += dwCodeSize + 8 
		dwCode = readDWORD() 
		dwCodeSize = readDWORD() 
	
   Wend

	return bone 
End Function

Function getTextureData() As sTexture 
	Print "   > reading a texture" 
	dim as sTexture tex
   tex._tSize = 8 
	dim as DWORD dwCode = readDWORD() 
	Dim As Integer dwCodeSize = readDWORD() 
	Print "     {" ; dwCode ; "," ;
	while(dwCode > 0)  
		Select Case (dwCode)  
         case 141
            tex.names = readSTRING(readDWORD())
         case 142
            tex.stage = readDWORD()
         case 143
            tex.blendmode = readDWORD()
         case 144
            tex.argument1 = readDWORD()
         case 145
            tex.argument2 = readDWORD()
         case 146
            tex.AddressU = readDWORD() 
         case 147
            tex.AddressV = readDWORD()
         case 148
            tex.mag = readDWORD() 
         case 149
            tex.min = readDWORD()
         case 150
            tex.mip = readDWORD() 
         case 151
            tex.TCMode = readDWORD()
         case 152
            tex.PrimitiveStart = readDWORD()
         case 153
            tex.PrimitiveCount = readDWORD()
			case else 
				readDATA(dwCodeSize) 
      End Select

		Print dwCode ; "," ;
		tex._tSize = tex._tSize + dwCodeSize + 8 
		dwCode = readDWORD() 
		dwCodeSize = readDWORD() 
	
   Wend
    
	Print "_tSize:" ; tex._tSize ; "}" 
	return tex 
End Function

Function getMaterial() As sMaterial 
	dim as sMaterial mat 
	Print "   > reading a material"
   dim as integer d,a,s,e
	for d=0 To 3          
      mat.diffuse(d) = readFLOAT()  
   Next
	for a=0 To 3          
      mat.ambient(a) = readFLOAT()  
   Next
	for s=0 To 3          
      mat.specular(s) = readFLOAT()  
   Next
	for e=0 To 3          
      mat.emissive(e) = readFLOAT()  
   Next
	return mat 
End Function

Function getMMaterial() As sMultipleMaterial 
	Print "  > reading a multiple material" 
	dim as sMultipleMaterial mat 
	dim as DWORD dwCode = readDWORD() 
	Dim As Integer dwCodeSize = readDWORD() 
	while(dwCode > 0)  
		Select Case (dwCode)  
         case 161 
            mat.names = readSTRING(readDWORD()) 

         case 162 
            mat.mat = getMaterial() 
            readDATA(dwCodeSize-64) 

         case 163 
            mat.start = readDWORD() 

         case 164 
            mat.count = readDWORD() 

         case 165 
            mat.polygons = readDWORD() 

         case else 
            readDATA(dwCodeSize) 
		
      End Select

		dwCode = readDWORD() 
		dwCodeSize = readDWORD() 
	
   Wend
   
	return mat 
End Function

Sub getMesh( m As sMeshData Ptr) 
	Print "  > reading a mesh  :" ; NumOBJ
	dim as DWORD dwCode = readDWORD() 
	Dim As Integer dwCodeSize = readDWORD() 
	while(dwCode > 0)  
		Select Case (dwCode)  
			case 111 
				m->FVF = readDWORD() 

			case 112 
				m->FVFSize = readDWORD() 

			case 113
				m->VertexCount = readDWORD() 

			case 114 
				m->IndexCount = readDWORD() 

			case 115
				if m->VertexCount>0 then
					for i As UInteger=0 To m->VertexCount -1        
						dim as sVertexData datas 
						datas.x  = readFLOAT()
						datas.y  = readFLOAT() 
						datas.z  = readFLOAT() 
						
						datas.nx = readFLOAT() 
						datas.ny = readFLOAT() 
						datas.nz = readFLOAT() 
						
						datas.tu = readFLOAT() 
						datas.tv = readFLOAT() 
						' añadida por mi, al parecer, el DBO que originalmente leia este fuente, lo hacia solo a 32bytes
						' pero son 40 (32+4+4). fijo que es de una nueva version de DBO
						datas.ju = readFLOAT() ' los leo como UV extras
						datas.jv = readFLOAT() ' y luego, al escribir al final del todo, añado un "2tcoords" (ver abajo del todo)
						m->VertexData(i)=datas
					Next
				endif
				' desconozco el porque, pero esta 
				' se supone que se salta el bloque restante que pueda quedar recien leido encima de aqui
				' que son todos los vertices*32.
				' pero si lo hace, falla cosas, y se salta texturas
				' creo que es, por que multiplica por 32, y deberia ser por 40
				' y lo mas probable es que sea por diferencia de versiones DBO
				readDATA(dwCodeSize - m->VertexCount*40) ' antes *32, ahora *40

			case 116
				if m->IndexCount>0 then
					for i As UInteger=0 To m->IndexCount -1        
						m->IndexData(i)=readWORD() 
					Next
				endif

			case 117 
				m->pType = readDWORD() 

			case 118 
				m->DrawVertexCount = readDWORD() 

			case 119 
				m->DrawPrimitiveCount = readDWORD() 

			case 120 
				readDATA(dwCodeSize) 

			case 121 
				m->BoneCount = readDWORD() 

			case 122 
				Dim As UInteger _tSize = 0 
				if m->BoneCount>0 then 
					for b As UInteger=0 To m->BoneCount-1         
						dim as sBoneData bone = getBoneData() 
						m->bone=bone
						_tSize += bone._tSize 
					Next
				endif

				if(m->BoneCount = 0) Then 
					readDATA(dwCodeSize) 
				else
					readDATA(dwCodeSize-_tSize) 
				EndIf
  
			case 125 
				m->bUseMaterial = readBOOL() 

			case 126 
				if(m->bUseMaterial) Then 
					m->mat = getMaterial() 
					readDATA(dwCodeSize-(4*4*4)) 
				else
					readDATA(dwCodeSize) 
            EndIf
  
			case 127
				m->TextureCount = readDWORD() 

			case 128 
				Dim As UInteger _tSize = 0 
				if m->TextureCount>0 then
					for t As UInteger=0 To m->TextureCount-1         
						dim as sTexture tex = getTextureData() 
						m->texture(t)=tex
						_tSize += tex._tSize 
					Next
				endif
				if(m->TextureCount = 0) Then 
               readDATA(dwCodeSize)
            else
					readDATA(dwCodeSize-_tSize) 
            EndIf
  
			case 140 
				m->bVisible = readBOOL() 

			case 129 
				m->bWireframe = readBOOL() 

			case 130 
				m->bLight = readBOOL() 

			case 131 
				m->bCull = readBOOL() 

			case 132 
				m->bFog = readBOOL() 

			case 133 
				m->bAmbient = readBOOL() 

			case 134 
				m->bTransparency = readBOOL() 

			case 135 
				m->bGhost = readBOOL() 

			case 136 
				m->GhostMode = readDWORD() 

			case 123 
				m->bUseMultipleMaterials = readBOOL() 

			case 124 
				m->MaterialCount = readDWORD() 

			case 139
				if m->MaterialCount>0 then
					for mm As UInteger=0 To m->MaterialCount-1         
						m->mmaterial=getMMaterial()
						getMMaterial()
					Next
				endif
				if(m->MaterialCount = 0) Then 
					readDATA(dwCodeSize) 
				EndIf
  
			case 154
				m->effectname = readSTRING(readDWORD()) 

			case 155 
				readDATA(dwCodeSize) 

			case 156 
				readDATA(dwCodeSize) 

			case 157 
				readDATA(dwCodeSize) 

			case 158 
				readDATA(dwCodeSize) 

			case 159 
				readDATA(dwCodeSize) 

			case 160 
				readDATA(dwCodeSize) 

			case 166 
				readDATA(dwCodeSize) 

			case else 
				readDATA(dwCodeSize) 

      End Select

		dwCode = readDWORD() 
		dwCodeSize = readDWORD() 

   Wend
  
End Sub

Sub getFrame() 
	obj->_cFrames+=1  
	Print "  > reading a frame : " ; obj->_cFrames
	Dim As Integer dwCode = readDWORD() 
	Dim As Integer dwCodeSize = readDWORD() 

	while( dwCode > 0 )  
		Select Case (dwCode)  
		case 101 
			obj->oFrame->bGood = true 
			obj->oFrame->names = readSTRING(readDWORD()) 

		case 102 
			for x As Integer =0 To 3         
				for y As Integer =0 To 3         
					obj->oFrame->matrix(x, y) = csng(readDWORD()) 
            Next
         Next

		case 103
			obj->oFrame->m = new sMeshData() 
			objetos(NumOBJ)=cptr(integer,obj->oFrame) ' guardo el puntero al objeto creado
			getMesh(obj->oFrame->m) 
			'print "Puntero a objeto:";objetos(NumOBJ)
			NumOBJ+=1

		case 104 
			obj->oFrame->child = new sFrame() 
			obj->oFrame = obj->oFrame->child 
			getFrame() 

		case 105 
			obj->oFrame->sibling= new sFrame() 
			obj->oFrame = obj->oFrame->sibling 
			getFrame() 

		case 106 
			obj->oFrame->offsets(0) = readFLOAT() 
			obj->oFrame->offsets(1) = readFLOAT() 
			obj->oFrame->offsets(2) = readFLOAT() 

		case 107 
			obj->oFrame->rot(0) = readFLOAT() 
			obj->oFrame->rot(1) = readFLOAT() 
			obj->oFrame->rot(2) = readFLOAT() 

		case 108 
			obj->oFrame->scale(0) = readFLOAT() 
			obj->oFrame->scale(1) = readFLOAT() 
			obj->oFrame->scale(2) = readFLOAT() 

		case else 
			readDATA(dwCodeSize) 
		
     End Select

		dwCode = readDWORD() 
		dwCodeSize = readDWORD() 

   Wend
   
End Sub




' ------------------------- LECTURAS --------------------------
Function readSTRING(size As UInteger) As String 
	dim as String buffer 
	for n As UInteger = 0 To  size-1         
		Dim As Byte c
      get #1,,c
      buffer+=chr(c)
   Next
	return buffer
End Function

Sub readDATA(size As UInteger) 
	if size>0 then 
		for n As UInteger = 0 To size-1         
			Dim As Byte c
			get #1,,c
		Next
	endif
End Sub

Function readFLOAT() As Single 
	Dim As Single temp = 0.0f 
   get #1,,temp
	return temp 
End Function

Function readINTEGER() As Integer 
	Dim As short temp = 0 
   get #1,,temp
	return temp 
End Function

Function readDWORD() As DWORD 
	dim as DWORD temp = 0 'NULL 
   get #1,,temp
	return temp 
End Function

Function readWORD() As WORD 
	dim as WORD temp = 0 'NULL 
   get #1,,temp
	return temp 
End Function

Function readBOOL() As bool 
	dim as bool temp = false 
   get #1,,temp
	return temp 
End Function




' -------------------------- FIN --------------------------
' grabamos resultado como IRRMESH
Sub irr_saveto() 

	Print " > saving to output format IRRMESH "

	irr_setMeshVersion("http://irrlicht.sourceforge.net/IRRMESH_09_2007","1.0") 
	Print "  > found " ; irr_getBufferCount() ; " buffers" 
	for f as integer=0 to NumOBJ-1
		irr_addBuffer(f) 
	next
	irr_addEnd("mesh") 

End Sub

' -------------------------------------------------------------------------
Function irr_getBufferCount() As UInteger 
   return Obj->_cFrames 
End Function

Sub irr_setMeshVersion(_namespace As String , version As String) 
	print #2,"<?xml version=";comillas;"1.0";comillas;"?>"
	Print #2, "<mesh xmlns=";comillas;_namespace;comillas;" version=";comillas;"1.0";comillas;">" 
End Sub

Sub irr_setBoundingBox(mins() As Single , maxs() As Single) 
	Print #2, "<boundingBox minEdge=";comillas; _ 
	   fmt6(mins(0));fmt6(mins(1));fmt6(mins(2));comillas; " maxEdge="; _
		comillas;fmt6(maxs(0));fmt6(maxs(1));fmt6(maxs(2));comillas;" />"
End Sub

Sub irr_addEnd(tag As String) 
	Print #2, "</" ; tag ; ">" 
End Sub

Sub irr_addBuffer( nobj as integer)  'left right tree search check and write
	dim as string sa
	dim as integer a
	dim as single mins(2),maxs(2)
	mins(0)=-100 : mins(1)=-100 : mins(2)=-100
	maxs(0)=100 : maxs(1)=100 : maxs(2)=100

	dim as sFrame ptr temp = cast(sFrame ptr,objetos(nobj)) 'nexts 
  
			Print #2, "<buffer>" 
				irr_setBoundingBox(mins(),maxs())
				Print #2, "<material>" 
				
					' activar esta , en lugar de la siguiente, para usar SOLO la textura normal, solida, sin luces
					'Print #2, "<enum name=";comillas;"Type";comillas;" value=";comillas;"solid";comillas;" />" 
					
					' activar esta en lugar de la anterior, para activar LUCES y SOMBRAS usando textura extra de luces
					Print #2, "<enum name=";comillas;"Type";comillas;" value=";comillas;"lightmap_m4";comillas;" />" 
					
					'Print #2, "<color name=";comillas;"Ambient";comillas;" value=";comillas;"ffffffff";comillas;" />" 
					'Print #2, "<color name=";comillas;"Diffuse";comillas;" value=";comillas;"ffffffff";comillas;" />" 
					'Print #2, "<color name=";comillas;"Emissive";comillas;" value=";comillas;"00000000";comillas;" />" 
					'Print #2, "<color name=";comillas;"Specular";comillas;" value=";comillas;"ffffffff";comillas;" />" 
					'Print #2, "<float name=";comillas;"Shininess";comillas;" value=";comillas;"1.000000";comillas;" />" 
					'Print #2, "<float name=";comillas;"Param1";comillas;" value=";comillas;"0.000000";comillas;" />" 
					'Print #2, "<float name=";comillas;"Param2";comillas;" value=";comillas;"0.000000";comillas;" />" 
					
					for tc As UInteger =0 To cuint(temp->m->TextureCount)-1  
						' arreglo las texturas para quitar la ruta original que pueda llevar, y poner una mas logica      
						sa=temp->m->texture(tc).names
						for f as integer=len(sa) to 1 step -1
							if mid(sa,f,1)="\" orelse mid(sa,f,1)="/" then a=f:exit for
						next
						if a=0 then
							sa=".\"+ficheroDBO+"\texturas\"+sa ' si no existe ruta, la incluyo
						else
							sa=".\"+ficheroDBO+"\texturas\"+mid(sa,a+1) ' si existe, la elimino y meto la mia hasta dentro, bien grande y tiesa
						endif
						Print #2, "<texture name=";comillas;"Texture"; tc+1 ;"";comillas;" value=";comillas; sa ; comillas;" />" 
               Next
					
					Print #2, "<bool name=";comillas;"Wireframe";comillas;" value=";comillas;"" ; "false" ; "";comillas;" />" 
					'Print #2, "<bool name=";comillas;"GouraudShading";comillas;" value=";comillas;"true";comillas;" />" 
					'Print #2, "<bool name=";comillas;"Lighting";comillas;" value=";comillas;"true";comillas;" />" 
					Print #2, "<bool name=";comillas;"ZWriteEnable";comillas;" value=";comillas;"true";comillas;" />" 
					Print #2, "<int name=";comillas;"ZBuffer";comillas;" value=";comillas;"1";comillas;" />" 
					Print #2, "<bool name=";comillas;"BackfaceCulling";comillas;" value=";comillas;"true";comillas;" />" 
					Print #2, "<bool name=";comillas;"FrontfaceCulling";comillas;" value=";comillas;"false";comillas;" />" 
					Print #2, "<bool name=";comillas;"FogEnable";comillas;" value=";comillas;"false";comillas;" />" 
					Print #2, "<bool name=";comillas;"NormalizeNormals";comillas;" value=";comillas;"false";comillas;" />" 
					Print #2, "<int name=";comillas;"AntiAliasing";comillas;" value=";comillas;"5";comillas;" />" 
					Print #2, "<int name=";comillas;"ColorMask";comillas;" value=";comillas;"15";comillas;" />" 
					Print #2, "<bool name=";comillas;"BilinearFilter1";comillas;" value=";comillas;"true";comillas;" />" 
					'Print #2, "<bool name=";comillas;"BilinearFilter2";comillas;" value=";comillas;"true";comillas;" />" 
					'Print #2, "<bool name=";comillas;"BilinearFilter3";comillas;" value=";comillas;"true";comillas;" />" 
					'Print #2, "<bool name=";comillas;"BilinearFilter4";comillas;" value=";comillas;"true";comillas;" />" 
					Print #2, "<bool name=";comillas;"TrilinearFilter1";comillas;" value=";comillas;"false";comillas;" />" 
					'Print #2, "<bool name=";comillas;"TrilinearFilter2";comillas;" value=";comillas;"false";comillas;" />" 
					'Print #2, "<bool name=";comillas;"TrilinearFilter3";comillas;" value=";comillas;"false";comillas;" />" 
					'Print #2, "<bool name=";comillas;"TrilinearFilter4";comillas;" value=";comillas;"false";comillas;" />" 
					Print #2, "<int name=";comillas;"AnisotropicFilter1";comillas;" value=";comillas;"false";comillas;" />" 
					'Print #2, "<int name=";comillas;"AnisotropicFilter2";comillas;" value=";comillas;"false";comillas;" />" 
					'Print #2, "<int name=";comillas;"AnisotropicFilter3";comillas;" value=";comillas;"false";comillas;" />" 
					'Print #2, "<int name=";comillas;"AnisotropicFilter4";comillas;" value=";comillas;"false";comillas;" />" 
					Print #2, "<enum name=";comillas;"TextureWrap1";comillas;" value=";comillas;"texture_clamp_repeat";comillas;" />" 
					'Print #2, "<enum name=";comillas;"TextureWrap2";comillas;" value=";comillas;"texture_clamp_repeat";comillas;" />" 
					'Print #2, "<enum name=";comillas;"TextureWrap3";comillas;" value=";comillas;"texture_clamp_repeat";comillas;" />" 
					'Print #2, "<enum name=";comillas;"TextureWrap4";comillas;" value=";comillas;"texture_clamp_repeat";comillas;" />" 
					'opcional Print #2, "<int name=";comillas;"LODBias1";comillas;" value=";comillas;"0";comillas;" />" 
					'opcional Print #2, "<int name=";comillas;"LODBias2";comillas;" value=";comillas;"0";comillas;" />" 
					'opcional Print #2, "<int name=";comillas;"LODBias3";comillas;" value=";comillas;"0";comillas;" />" 
					'opcional Print #2, "<int name=";comillas;"LODBias4";comillas;" value=";comillas;"0";comillas;" />" 
				Print #2, "</material>" 
				
				' he visto que hay dos maneras de leer los vertices:
				' una lee 32 bytes, que son XYZ+UVW+UV y la otra son 40bytes XYZ+UVW+UV+UV
				' desconozco que es cada formato, pero si es el primero, el original con el que venia este fuente
				' entonces, debemos poner STANDARD en la fila que sigue
				' si es el formato con un UV extra (40 bytes), debemos poner 2TCOORDS y sñadir la fila de abajo extra de datos
				'Print #2, "<vertices type=";comillas;"standard";comillas;" vertexCount=";comillas;"" ; temp->m->VertexCount ; "";comillas;">" 
				Print #2, "<vertices type=";comillas;"2tcoords";comillas;" vertexCount=";comillas;"" ; temp->m->VertexCount ; "";comillas;">" 
				for v As UInteger=0 To temp->m->VertexCount-1         
					Print #2, fmt6(temp->m->VertexData(v).x)  ; " " ; fmt6(temp->m->VertexData(v).y)  ; " " ; fmt6(temp->m->VertexData(v).z)  ; " " ; _ 
                         fmt6(temp->m->VertexData(v).nx) ; " " ; fmt6(temp->m->VertexData(v).ny) ; " " ; fmt6(temp->m->VertexData(v).nz) ; " " ; _ 
                         "FFFFFFFF" ; " " ; _ ' este valor desconozco que es, pero lo he visto como "00000000" o "64FFFFFF"
								 fmt6(temp->m->VertexData(v).tu) ; " " ; fmt6(temp->m->VertexData(v).tv) ; _
                         fmt6(temp->m->VertexData(v).ju) ; " " ; fmt6(temp->m->VertexData(v).jv) 'fila extra de UV para el formato "2tcoords"
            Next
				
				Print #2, "</vertices>" 
				
				if(temp->m->IndexCount = 0) Then 
					Print #2, "<indices indexCount=";comillas;temp->m->VertexCount ; "";comillas;">" 
					for i As UInteger=0 To temp->m->VertexCount-1         
						Print #2, i ; " ";
               Next
					print #2,""
				 else
					Print #2, "<indices indexCount=";comillas ; temp->m->IndexCount;comillas;">" 
					for i As UInteger=0 To temp->m->IndexCount-1         
						Print #2, temp->m->IndexData(i) ; " " ;
               Next
					print #2,""
            EndIf
  
			Print #2, "</indices>" 
			Print #2, "</buffer>" 

End Sub



' conversion DBO DarkBasic a Malla IRRLITCH .IRRMESH

ficheroDBO=command
if ficheroDBO="" then Print "falta el fichero DBO.":sleep:end

a=instrrev(ficheroDBO,"\") ' quito la ruta, si la lleva
if a then ficheroDBO=mid(ficheroDBO,a+1)

a=instrrev(ficheroDBO,".") ' quito la extension si la lleva
if a then ficheroDBO=left(ficheroDBO,a-1)

open ficheroDBO+".dbo" for binary as 1
   create()
close 1

' salida en formato IRRMESH (malla estatica IRR, extension OBLIGATORIA, por que sino, IRRLITCH no lo reconoce)
open ficheroDBO+".irrmesh" for output as 2
	irr_saveto()
close 2
