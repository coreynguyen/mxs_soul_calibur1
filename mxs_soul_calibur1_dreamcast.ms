
/*               Maxscript: Soul Calibur for Arcade
   
   --------------------------------------------------------------
   Written By: mariokart64n
   Date      : Feburary 22 2025
   Credits   : spaztron64
   
   spaztron64:
	   https://github.com/spaztron64
       https://twitter.com/spaztron64
	
   --------------------------------------------------------------
   
   Notes     :
	spaztron64 did alot of the heavy lifting in the reverse 
	engineering, this is just my implmentation based on his
	findings
	
*/ --------------------------------------------------------------
gc()
clearListener()
try(DestroyDialog SC2_DC_Importer)catch(SC2_DC_Importer)
rollout SC2_DC_Importer "SC2 DC Mesh" (

	button btn "Import Model" width:120 height:30
	checkBox chk_clear "Clear Scene on Import" checked:true
	checkBox chk_skin "Weights" checked:true
	checkBox chk_bskl "Skeleton" checked:true
	group "Debug Options" (
		checkBox chk_normls "Apply Normals" checked:false
		)
	label lbl1 "Written By: mariokart64n" align:#left
	label lbl2 "Date: Feb 22, 2025" align:#left
	
	struct DcSc2_SubMesh_t ( -- 32 Bytes
		/*uint8_t*/   	bone_id0 = 0, -- on weapons this is NULL?
		/*uint8_t*/   	bone_id1 = 0,
		/*uint16_t*/  	unk011 = 0,
		/*uint32_t*/  	vert_addr = 0,
		/*uint32_t*/  	bone_addr = 0,
		/*uint16_t*/  	vert_count = 0,
		/*uint16_t*/  	norm_count = 0,
		/*int16_t*/   	rot_x = 0,
		/*int16_t*/   	rot_y = 0,
		/*int16_t*/   	rot_z = 0,
		/*int16_t*/   	unk017 = 0, -- Type of Bone Controller?
		/*int16_t*/   	pos_x = 0,
		/*int16_t*/   	pos_y = 0,
		/*int16_t*/   	pos_z = 0,
		/*int16_t*/   	parent = 0,
		
		fn read &f = (
			bone_id0 = readByte f #unsigned
			bone_id1 = readByte f #unsigned
			unk011 = readShort f #unsigned
			vert_addr = readLong f #unsigned
			bone_addr = readLong f #unsigned -- always 0
			vert_count = readShort f #unsigned
			norm_count = readShort f #unsigned
			rot_x = readShort f #signed
			rot_y = readShort f #signed
			rot_z = readShort f #signed
			unk017 = readShort f #signed -- always 0
			pos_x = readShort f #signed
			pos_y = readShort f #signed
			pos_z = readShort f #signed
			parent = readShort f #signed
			)
		)

	struct DcSc2_Vertex_t ( -- 16 bytes
		/*float[3]*/  vertex      = [0.0, 0.0, 0.0],
		/*uint16_t*/ index  = 0, -- lower16
		/*uint16_t*/ flags  = 0, -- upper16
		fn isCmdPresent = (index >= 32768),
		fn getIndex = (bit.and index 0xFFF),
		fn getWComp = (bit.intAsFloat( (bit.shift flags 16) + index )),
		fn read f = (
			vertex      = [readFloat f, readFloat f, readFloat f] * 16000.0
			index           = readShort f #unsigned
			flags           = readShort f #unsigned
			)
		)
	
	struct DcSc2_Triangle_t ( -- 8 bytes
		/*uint16_t*/ vertex_index   = 0,
		/*uint16_t*/ normal_index   = 0,
		/*int16_t*/ uVal           = 0,
		/*int16_t*/ vVal           = 0,
		uVal2 = 0.0,
		vVal2 = 0.0,
		fn read f = (
			vertex_index    = readShort f #unsigned
			normal_index    = readShort f #unsigned
			uVal            = readShort f #signed
			vVal            = readShort f #signed
			
 
			vVal2 = bit.intAsFloat (bit.shift uVal 16)

			fseek f -4 #seek_cur
			uVal2 = readFloat f -- seems to work
			
			)
		)

	struct DcSc2_BoneInfo_t (
		/*uint16_t*/type = 0,
		/*void*/data = undefined, 
		fn read f = (
			result = true
			type = readShort f #unsigned
			case type of (
				0: (
					data = readString f
					fseek f ((mod (4-(mod (data.count + 4) 4)) 4) + 1) #seek_cur
					)
				1: (
					data = #(readByte f #unsigned, readByte f #unsigned, readFloat f)
					)
				2: (
					data = #(readByte f #unsigned, readByte f #unsigned, readFloat f)
					)
				4: (
					data = #(readByte f #unsigned, readByte f #unsigned, readFloat f)
					)
				default: (
					format "unknown type: % @ %\n" type ((ftell f - 2) as integer)
					result = false
					)
				)
			result
			)
		)
	
	struct DcSc2_TriStrip_t ( -- 4 bytes + n bytes
		/*uint8_t*/         strip_length    = 0, -- not a length?
		/*uint8_t*/         unkByte         = 0,
		/*uint8_t*/         uv_coordinate   = 0,
		/*uint8_t*/         count           = 0,
		/*DcSc2_Triangle_t[]*/   triangles       = #(), -- 8 bytes
		
		fn read f = (
			strip_length            = readByte f #unsigned
			unkByte                 = readByte f #unsigned
			uv_coordinate           = readByte f #unsigned
			count                   = readByte f #unsigned
			
			triangles               = #()
			if count > 0 do (
				triangles[count]    = DcSc2_Triangle_t()
				for i = 1 to count do (
					triangles[i]    = DcSc2_Triangle_t()
					triangles[i].read(f)
					)
				)
			count > 0
			)
		)

	struct DcSc2_t ( -- 32 bytes
		
		/*char[20]*/       guid                             = #(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
		/*uint32_t*/       unk23 = 0,
		/*uint16_t*/       vertex_pool_count                = 0,
		/*uint16_t*/       normal_pool_count                = 0,
		/*uint32_t*/       triangle_strip_table_pointer     = 0,
		/*uint16_t*/       submesh_count                    = 0,
		/*uint16_t*/       strip_count                      = 0,
		
		/*DcSc2_SubMesh_t[]*/table1 = #(),
		/*DcSc2_Vertex_t[]*/table2 = #(),
		/*DcSc2_TriStrip_t[]*/table3 = #(),
		/*DcSc2_BoneInfo_t[]*/table4 = #(),
		
		-- not apart of the actual file
		/*uint32_t[]*/table2_offsets = #(), -- use to reference entries
		/*uint32_t[]*/table4_offsets = #(), -- use to reference entries
		fn read f = (
			
			-- Get File size, so we can read the data and ignore counts / pointers
			fseek f 0 #seek_end
			local fsize = ftell f
			fseek f 0 #seek_set
			
			-- read header
			guid                            = #(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
			for i = 1 to 20 do (
				guid[i]                     = readbyte f #unsigned
				)
			vertex_pool_count               = readShort f #unsigned
			normal_pool_count               = readShort f #unsigned
			triangle_strip_table_pointer    = readLong f #unsigned
			submesh_count                   = readShort f #unsigned
			strip_count                     = readShort f #unsigned
			
			-- Read submesh table
			table1 = #()
			if submesh_count > 0 and strip_count > 0 do (
				
				-- Calculate the start of and end of the vertices from the table1 entries
				local VertStart = fsize
				local VertEnd = triangle_strip_table_pointer
				local VertCount = 0
				local BoneStart = fsize
				
				table1[submesh_count] = DcSc2_SubMesh_t()
				for i = 1 to submesh_count do (
					table1[i] = DcSc2_SubMesh_t()
					table1[i].read(f)
					
					if table1[i].vert_addr > VertEnd do VertEnd = table1[i].vert_addr
					if table1[i].vert_addr < VertStart do VertStart = table1[i].vert_addr
					if table1[i].bone_addr > 0 and table1[i].bone_addr < BoneStart do BoneStart = table1[i].bone_addr
					)
				
				VertCount = ((VertEnd - VertStart) / 16) as integer
				
				-- Based on calculated vertex count, read the verts
				table2 = #()
				table2_offsets = #()
				if VertCount > 0 do (
					table2[VertCount] = DcSc2_Vertex_t()
					table2_offsets[VertCount] = 0
					for i = 1 to VertCount do (
						table2_offsets[i] = (ftell f) as integer
						table2[i] = DcSc2_Vertex_t()
						table2[i].read(f)
						)
					)
				
				-- read the faces until we reach the bones
				fseek f triangle_strip_table_pointer #seek_set
				table3 = #()
				local strip_index = 0
				while ftell f + 8 < BoneStart do (
					local o = DcSc2_TriStrip_t()
					o.read(f)
					append table3 o
					strip_index += 1
					)
				
				-- read the bones until the end of the file
				fseek f BoneStart #seek_set
				table4 = #()
				table4_offsets = #()
				while ftell f < fsize do (
					local o = DcSc2_BoneInfo_t()
					append table4_offsets ((ftell f) as integer)
					if o.read(f) then (
						append table4 o
						)
					else (
						exit
						)
					)
				)
			),
		fn buildBoneTransforms = (
			-- Convert Bones from Local to World Space
			
			local tfm = matrix3 1
			local boneTrans = #()
			local num_bones = table1.count
			local rot = [0.0, 0.0, 0.0]
			for i = 1 to num_bones do (
				rot = ([table1[i].rot_x, table1[i].rot_y, table1[i].rot_z] / 32767.0 * 180.0)
				tfm = (EulerAngles rot[1] rot[2] rot[3]) as matrix3
				tfm.row4 = [table1[i].pos_x, table1[i].pos_y, table1[i].pos_z]
				append boneTrans tfm
				)
			for i = 1 to num_bones do (
				if table1[i].parent > -1 and table1[i].parent != i - 1 do (
					boneTrans[i] *= boneTrans[table1[i].parent + 1]
					)
				)
			boneTrans
			),
		fn normalizeWeights weights = (
			local total = 0.0
			for w in weights do total += w
			local normalizedWeights = for w in weights collect (w / total)
			normalizedWeights
			),
		fn build debug:false impBones:true impNormals:false impWeights:false mscale:(1.0 / 254.0) flipAxis:true clearScene:true = (
			/*--------------------------------------------------
			  1) Clean scene & enter modify mode
			--------------------------------------------------*/
			if clearScene do delete objects
			max modify mode
			
			/*--------------------------------------------------
			  2) Build & optionally scale bone transforms
			--------------------------------------------------*/
			local boneTrans = buildBoneTransforms()  -- Precomputed bone transforms
			local num_bones = boneTrans.count
			
			for b = 1 to num_bones do (
				boneTrans[b].row4 *= mscale
				)
			
			/*--------------------------------------------------
			  3) Create dummies to visualize bones
			--------------------------------------------------*/
			local boneArray = #()
			if impBones do (
				for b = 1 to num_bones do (
					local bn = Dummy()
					bn.wirecolor = yellow
					bn.transform = boneTrans[b]
					if flipAxis do bn.transform*= RotateXMatrix 90
					--local bone_index = findItem table4_offsets table1[b].bone_addr
					--if bone_index > 0 and table4[bone_index].data != undefined and classOf table4[bone_index].data == String do (
					--	bn.name = table4[bone_index].data
					--	)
					append boneArray bn
					)
				
				
				/*--------------------------------------------------
				  4) Set up parenting
				--------------------------------------------------*/
				for b = 1 to num_bones do (
					boneArray[b].showLinks      = true
					boneArray[b].showLinksOnly  = true
					
					-- If there's a valid parent, set it
					if table1[b].parent > -1 and table1[b].parent != b - 1 do (
						boneArray[b].parent = boneArray[ table1[b].parent + 1 ]
						)
					)
				)
			/*--------------------------------------------------
			  5) Determine maximum vertex index
			--------------------------------------------------*/
			local vertex_count = 0
			for v = 1 to table2.count do (
				local idx = table2[v].getIndex() + 1
				if idx > vertex_count do vertex_count = idx
				)
			
			--------------------------------------------------*/
			local boneVerts      = #()
			local boneNorms      = #()
			local boneIds        = #()
			local boneWes        = #()
			local vertArrayData  = #()
			
			if vertex_count > 0 do (
				
				boneVerts[vertex_count]     = #()
				boneNorms[vertex_count]     = #()
				boneIds[vertex_count]       = #()
				boneWes[vertex_count]       = #()
				vertArrayData[vertex_count] = #()
				
				for i = 1 to vertex_count do (
					boneIds[i]       = #()
					boneWes[i]       = #()
					boneVerts[i]     = #()
					boneNorms[i]     = #()
					vertArrayData[i] = #()
					)
				
				/*--------------------------------------------------
				  7) Read each bone's vertex block and compute transforms
				--------------------------------------------------*/
				for b = 1 to num_bones do (
					local vert_index = findItem table2_offsets table1[b].vert_addr
					local endIndex   = vert_index + table1[b].vert_count - 1
					
					for j = vert_index to endIndex do (
						local idx  = table2[j].getIndex() + 1
						local wVal = table2[j].getWComp()  -- The 4th float (or reinterpreted bits)
						
						-- Simple approach: (x,y,z)/wVal => transMatrix => boneTrans => row4
						local tpos = (transMatrix (table2[j].vertex * mscale / wVal)) * boneTrans[b]
						append boneVerts[idx]     tpos.row4
						append vertArrayData[idx] table2[j]
						append boneIds[idx] b
						append boneWes[idx] wVal
						)
					
					vert_index = endIndex
					endIndex   = vert_index + table1[b].vert_count - 1
					for j = vert_index to endIndex do (
						local idx  = table2[j].getIndex() + 1
						local wVal = table2[j].getWComp()
						local tpos = (transMatrix table2[j].vertex) * boneTrans[b]
						append boneNorms[idx]     tpos.row4
						)
					)
				
				/*--------------------------------------------------
				  8) Combine partial transforms (Set/Add)
				--------------------------------------------------*/
				local vertArray = for v=1 to vertex_count collect [0,0,0]
				local boneIdArray = for v=1 to vertex_count collect #(1)
				local weightArray = for v=1 to vertex_count collect #(1.0)
				for i = 1 to vertex_count while boneVerts[i] != undefined do (
					local finalVertPos = [0,0,0]
					for j = 1 to boneVerts[i].count do (
						-- Use isCmdPresent() to decide if we "set" or "add"
						if vertArrayData[i][j].isCmdPresent() then (
							finalVertPos = boneVerts[i][j]
							)
						else (
							finalVertPos += boneVerts[i][j]
							)
						)
					
					if flipAxis do (
						finalVertPos = [finalVertPos[1], -finalVertPos[3], finalVertPos[2]]
						)
					vertArray[i]   = finalVertPos
					boneIdArray[i] = boneIds[i]
					--weightArray[i] = for w = 1 to boneVerts[i].count collect (1.0 / boneVerts[i].count)
					weightArray[i] = normalizeWeights boneWes[i]
					)
				
				local normArray = for v=1 to vertex_count collect [1,0,0]
				for i = 1 to vertex_count while boneNorms[i] != undefined do (
					local finalNormPos = [1,0,0]
					for j = 1 to boneVerts[i].count do (
						local thisNorm = if j <= boneNorms[i].count then boneNorms[i][j] else [1,0,0]
						if vertArrayData[i][j].isCmdPresent() then (
							finalNormPos = thisNorm
							)
						else (
							finalNormPos += thisNorm
							)
						)
					
					if flipAxis do (
						finalNormPos = [finalNormPos[1], -finalNormPos[3], finalNormPos[2]]
						)
					normArray[i]   = finalNormPos
					)
				
				/*--------------------------------------------------
				  9) Build faces *and* collect UV data
				--------------------------------------------------*/
				local faceArray     = #()
				local faceNormArray     = #()
				local matIdArray    = #()
				local uniqueMatIds  = #()
				
				-- We'll store all UV coords (tvertArray) as we read them
				local tvertArray  = #()
				
				-- We'll build a TV face array (tvFaces) that parallels faceArray
				local tvFaces = #()
				
				for s = 1 to table3.count do (
					if table3[s].strip_length == 0 do continue
					
					-- If using multiple materials, track them
					local matid = findItem uniqueMatIds table3[s].strip_length
					if matid == 0 do (
						append uniqueMatIds table3[s].strip_length
						matid = uniqueMatIds.count
						)
					
					local triCount = table3[s].triangles.count
					for k = 1 to (triCount - 2) do (
						local iIndex = k - 1
						local face, nface
						local uvIndices = #()  -- We'll store the 3 new uvIndices
						
						------------------------------------------------------------------
						-- We'll gather the 3 vertices (k, k+1, k+2) in "strip order".
						-- Also gather their (uVal, vVal).
						-- Typically Dreamcast uses 16-bit 0..65535 for UV range
						------------------------------------------------------------------
						local idx1 = (bit.and table3[s].triangles[k].vertex_index 0xFFF)
						local nrm1 = (bit.and table3[s].triangles[k].normal_index 0xFFF)
						local u1   = table3[s].triangles[k].uVal2
						local v1   = 1.0 - table3[s].triangles[k].vVal2  -- flip v if needed
						
						local idx2 = (bit.and table3[s].triangles[k+1].vertex_index 0xFFF)
						local nrm2 = (bit.and table3[s].triangles[k+1].normal_index 0xFFF)
						local u2   = table3[s].triangles[k+1].uVal2
						local v2   = 1.0 - table3[s].triangles[k+1].vVal2
						
						local idx3 = (bit.and table3[s].triangles[k+2].vertex_index 0xFFF)
						local nrm3 = (bit.and table3[s].triangles[k+2].normal_index 0xFFF)
						local u3   = table3[s].triangles[k+2].uVal2
						local v3   = 1.0 - table3[s].triangles[k+2].vVal2
						
						if bit.and iIndex 1 > 0 then (
							face = [idx1, idx3, idx2] + 1
							nface = [nrm1, nrm3, nrm2] + 1
							------------------------------------------------------------------
							-- For each of the 3 corners, append the uv coords to tvertArray
							-- store their index in uvIndices
							------------------------------------------------------------------
							
							append tvertArray [u1, v1, 0]
							append uvIndices tvertArray.count
							
							append tvertArray [u3, v3, 0]
							append uvIndices tvertArray.count
							
							append tvertArray [u2, v2, 0]
							append uvIndices tvertArray.count
							)
						else (
							face = [idx1, idx2, idx3] + 1
							nface = [nrm1, nrm2, nrm3] + 1
							
							-- same approach for the UV coords, but we swap the last two
							append tvertArray [u1, v1, 0]
							append uvIndices tvertArray.count
							
							append tvertArray [u2, v2, 0]
							append uvIndices tvertArray.count
							
							append tvertArray [u3, v3, 0]
							append uvIndices tvertArray.count
							)
						
						append matIdArray matid
						append faceArray face
						append faceNormArray nface
						------------------------------------------------------------------
						-- now store tvFaces referencing the newly appended uvIndices
						------------------------------------------------------------------
						append tvFaces uvIndices
						)
					)
				
				/*--------------------------------------------------
				  10) Create the mesh
				--------------------------------------------------*/
				local msh = mesh vertices:vertArray faces:faceArray tverts:tvertArray materialIds:matIdArray
				
				buildTVFaces msh
				
				msh.backfacecull = on
				msh.displayByLayer = false
				msh.wirecolor = random (color 0 0 0) (color 255 255 255)
				
				
				/*--------------------------------------------------
				  11) Assign UVs to the mesh
				--------------------------------------------------*/
				for i = 1 to tvFaces.count do (setTVFace msh i [tvFaces[i][1], tvFaces[i][2], tvFaces[i][3]])
				for i = 1 to msh.numfaces do setFaceSmoothGroup msh i 1
				
				update msh
				select msh
				
				-- Optional: add MultiMaterial
				msh.material = MultiMaterial numSubs:uniqueMatIds.count
				for m = 1 to uniqueMatIds.count do (
					msh.material[m]             = StandardMaterial()
					msh.material[m].diffuse     = random white black
					msh.material[m].specularLevel= random 20 60
					msh.material[m].glossiness  = random 0 50
					)
				
				setNumTVerts msh tvertArray.count
				
				for i = 1 to tvertArray.count do (
					local uv3 = tvertArray[i]  -- a point3, e.g. [u,v,0]
					setTVert msh i uv3.x uv3.y uv3.z
					)
				
				if impNormals do (
	-- 				local normMod = Edit_Normals()
	-- 				addmodifier msh normMod ui:off
	-- 				select msh
	-- 				modPanel.setCurrentObject normMod
	-- 				normMod.selectBy = 1
	-- 				normMod.displayLength = 0.64516 * mscale
	-- 				normMod.MakeExplicit selection:#{1..(normArray.count)}
	-- 				local normID = #{}
	-- 				--apply normals
	-- 				for i = 1 to normArray.count do (
	-- 					normID = #{} --free normID
	-- 					normMod.ConvertVertexSelection #{i} &normID
	-- 					for ii in normID do (
	-- 						normMod.SetNormal ii (normalize normArray[i])
	-- 						)
	-- 					)
	-- 				--collapseStack msh
	-- 				subobjectLevel = 0
					
					local normMod = Edit_Normals()
					addmodifier msh normMod ui:off
					select msh
					modPanel.setCurrentObject normMod

					-- Optional: tweak display
					normMod.selectBy = 1  -- "Normal"
					normMod.displayLength = 1.0
					normMod.MakeExplicit selection:#{1..(normArray.count)}

					-- For each face corner, get the normal ID and set it
					for f = 1 to faceNormArray.count do (
						for c = 1 to 3 do (
							local normalID  = normMod.GetNormalID f c
							local normalIdx = faceNormArray[f][c]  -- an index into normArray
							local theNormal = if normalIdx <= normArray.count then normArray[normalIdx] else [1,0,0]
							theNormal = normalize theNormal
							normMod.SetNormal normalID theNormal
							)
						)
					
					-- If you want to collapse or finish:
					-- collapseStack msh
					subobjectLevel = 0
					update msh
					)
				
				if impWeights and boneArray.count > 0 do (
					
					-- Apply a skin modifier
					local skinMod = skin()
					addModifier msh skinMod ui:off
					select msh
					
					-- Assign bones to skin modifier
					for i = 1 to boneArray.count do (
						skinOps.addbone skinMod boneArray[i]  (
							if i == boneArray.count then 1 else 0
							)
						)
					
					-- Get names of bones in skin list
					local bneTmp = #()
					bneTmp[boneArray.count] = ""
					for i = 1 to boneArray.count do (
						bneTmp[i] = skinOps.GetBoneName skinMod i 0
						)
					
					-- create a bonemap
					local boneMap = #()
					boneMap[boneArray.count] = 1
					for i = 1 to boneArray.count do (
						boneMap[i] = 1 -- default assignment to first bone in skin list
						local bone_index = findItem bneTmp boneArray[i].name
						if bone_index > 0 do (boneMap[i] = bone_index)
						)
					
					
					-- apply weights to skin modifier
					modPanel.setCurrentObject skinMod
					for i = 1 to weightArray.count do (
						local numBones = weightArray[i].count
						local bi = #()
						local bw = #()
						if numBones > 0 do (
							for ii = 1 to numBones do (
								local bone_index = boneIdArray[i][ii]
								if bone_index > -1 and weightArray[i][ii] > 0.00001 do (
									bone_index = boneMap[bone_index]
									append bi bone_index
									append bw weightArray[i][ii]
									)
								
								)
							--format "%: \t%, %\n" i (bi as string) (bw as string)
							skinOps.ReplaceVertexWeights skinMod i bi bw
							)
						)
					
					if skinOps.isWeightToolOpen skinMod == 0 do (
						skinOps.WeightTool skinMod
						)
					skinMod.filter_vertices = on
					)
				
				)
			)
		)
	
	fn read file = (
        f = try(fOpen file "rb")catch(undefined)
        if f != undefined then (
            local dcFile = DcSc2_t()
			dcFile.read(f)
			dcFile.build()
            fClose f
			) else (format "Unable to open f: %\n" file)
		)
	
	on btn pressed do (
		local file = GetOpenFileName caption:"Select a File" types: "SC1 (Dreamcast) Model (*.bin)|*.BIN|All files (*.*)|*.*|"
		if file != undefined and file != "" do (
			f = try(fOpen file "rb")catch(undefined)
			if f != undefined then (
				local dcFile = DcSc2_t()
				dcFile.read(f)
				dcFile.build debug:false impBones:chk_bskl.checked impWeights:chk_skin.checked clearScene:chk_clear.checked impNormals:chk_normls.checked
				fClose f
				) else (format "Unable to open f: %\n" file)
			)
		)
	)
CreateDialog SC2_DC_Importer
/*
SC2_DC_Importer.read (
	"E:\\BackUp\\MyCloud4100\\Coding\\Maxscripts\\File IO\\Soul Calibur 1 (Dreamcast)\\samples\\xianghua_DC_1p_decompressed.bin"
-- 	"G:\\StableDiffusion\\traindata\\sc1_mxs\\kilik1P_dc_decompresed.bin"
	)
*/