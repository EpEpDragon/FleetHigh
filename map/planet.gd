extends MeshInstance3D

const S = 64*3
const W = S*6
const H = S
const LS = 32

@export var n_plates := 10
@export_range(0.0, 0.1) var warp_freq := 0.01
@export_range(0.0, 1.0) var warp_gain := 0.5
@export_range(0.0, 100.0) var warp_amp := 50.0

var random := RandomNumberGenerator.new()

func _ready():
	random.seed = 4
	var rd := RenderingServer.create_local_rendering_device()
#	# HACK To include noise library
#	#+ FileAccess.get_file_as_string("res://map/fast_noise_lite.glsl") +
#	var shader_str := FileAccess.get_file_as_string("res://map/compute_planet.glsl")
#	var shader_src := RDShaderSource.new()
#	shader_src.set_stage_source(RenderingDevice.SHADER_STAGE_COMPUTE, shader_str)
	var shader_file := load("res://map/compute_planet.glsl")
#	var shader_spirv := rd.shader_compile_spirv_from_source(shader_src)
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	print(shader_spirv.compile_error_compute)
	var shader := rd.shader_create_from_spirv(shader_spirv)
	
	# Props
	var properties_bytes := make_properties_byte_array()
#	var properties_bytes := PackedFloat32Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]).to_byte_array()
	var properties_buffer := rd.storage_buffer_create(properties_bytes.size(), properties_bytes)
	var properties_uniform := RDUniform.new()
	properties_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	properties_uniform.binding = 0
	properties_uniform.add_id(properties_buffer)
	
	# Out
	var fmt := RDTextureFormat.new()
	fmt.width = W
	fmt.height = H
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	var output_image := Image.create(W, H, false, Image.FORMAT_RGBAF)
	
	var velocity_tex := rd.texture_create(fmt, RDTextureView.new(), [output_image.get_data()])
	var velocity_tex_uniform := RDUniform.new()
	velocity_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	velocity_tex_uniform.binding = 1
	velocity_tex_uniform.add_id(velocity_tex)
	
	var pressure_tex_x := rd.texture_create(fmt, RDTextureView.new(), [output_image.get_data()])
	var pressure_tex_x_uniform := RDUniform.new()
	pressure_tex_x_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	pressure_tex_x_uniform.binding = 2
	pressure_tex_x_uniform.add_id(pressure_tex_x)
	
	var pressure_tex_xy := rd.texture_create(fmt, RDTextureView.new(), [output_image.get_data()])
	var pressure_tex_xy_uniform := RDUniform.new()
	pressure_tex_xy_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	pressure_tex_xy_uniform.binding = 3
	pressure_tex_xy_uniform.add_id(pressure_tex_xy)
	
	# AtomicCounter
	var counter_buffer := rd.storage_buffer_create(4, PackedByteArray([0,0,0,0]))
	var counter_uniform := RDUniform.new()
	counter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	counter_uniform.binding = 5
	counter_uniform.add_id(counter_buffer)
	
	var uniform_set := rd.uniform_set_create([properties_uniform, velocity_tex_uniform, pressure_tex_x_uniform, pressure_tex_xy_uniform, counter_uniform], shader, 0)
	
	var pipeline := rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)

	rd.compute_list_set_push_constant(compute_list,PackedByteArray([ 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 ]),16)
#	rd.barrier(RenderingDevice.BARRIER_MASK_COMPUTE)
	rd.full_barrier()
	rd.compute_list_dispatch(compute_list, W/LS, H/LS, 6)
	
#	rd.barrier(RenderingDevice.BARRIER_MASK_COMPUTE)
	rd.full_barrier()
	rd.compute_list_set_push_constant(compute_list,PackedByteArray([ 1,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 ]),16)
	rd.compute_list_dispatch(compute_list, W/LS, H/LS, 6)
	
	rd.full_barrier()
	rd.compute_list_set_push_constant(compute_list,PackedByteArray([ 2,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 ]),16)
	rd.compute_list_dispatch(compute_list, W/LS, H/LS, 6)
	
	rd.compute_list_end()
	
	rd.submit()
	rd.sync()
	
	var byte_data := rd.texture_get_data(velocity_tex, 0)
	output_image.set_data(W, H, false, Image.FORMAT_RGBAF, byte_data)
	var image_texture := ImageTexture.create_from_image(output_image)
	output_image.save_png("res://Velocity.png")
	
	byte_data = rd.texture_get_data(pressure_tex_xy, 0)
	output_image.set_data(W, H, false, Image.FORMAT_RGBAF, byte_data)
	image_texture = ImageTexture.create_from_image(output_image)
	mesh.surface_get_material(0).set("albedo_texture", image_texture)
	output_image.save_png("res://Pressure.png")
	
	print(rd.buffer_get_data(counter_buffer).to_int32_array())


func make_properties_byte_array() -> PackedByteArray:
#	var props_bytes = PackedFloat32Array([warp_freq, warp_gain, warp_amp]).to_byte_array()
	var props_bytes = gen_plate_positioins(n_plates).to_byte_array()
#	props_bytes.append_array(PackedFloat32Array([0,1,0,0, 0,0,1,0, 0,0,0,1]).to_byte_array())
#	props_bytes.append_array(PackedByteArray([0,0,0,0]))
	return props_bytes


func gen_plate_positioins(n : int) -> PackedFloat32Array:
	var plate_positions : PackedFloat32Array
	plate_positions.resize(n * 8)
	for i in range(0, n*8, 8):
		var normal = Vector3(random.randfn(), random.randfn(), random.randfn()).normalized()
#		var x = random.randfn()
#		var y = random.randfn()
#		var z = random.randfn()
#		var l = sqrt(x*x + y*y + z*z)
		plate_positions[i] = normal.x
		plate_positions[i+1] = normal.y
		plate_positions[i+2] = normal.z
		var tangent = normal.cross(Vector3(random.randfn(), random.randfn(), random.randfn()).normalized())
		plate_positions[i+3] = tangent.x
		plate_positions[i+4] = tangent.y
		plate_positions[i+5] = tangent.z
		plate_positions[i+6] = random.randfn()/2 + 0.5
		plate_positions[i+7] = 0 # Padding
	return plate_positions

