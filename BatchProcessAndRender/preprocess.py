import pymeshlab as ml

ms = ml.MeshSet()

#note: the pymeshlab documentation allows you to directly convert menu name to the associated method for filter
#note: do not assign variable names to transformations. This will return a None object 


#set where you are storing your meshes 
mesh_path = 'C:/Users/tw1700/OneDrive - University of York/Documents/PhDCore/Experiments/PilotDataSet/'

filename = 'mesh'

extension = '.obj'

files = mesh_path+filename+extension 

#load mesh 
ms.load_new_mesh(files)


ms.compute_matrix_from_scaling_or_normalization(
    axisx=1.0,
    axisy=1.0,
    axisz=1.0,
    uniformflag=True,
    scalecenter='origin',  # Change to other options if needed
    customcenter=[0.0, 0.0, 0.0],
    unitflag=True,
    freeze=True,
    alllayers=False
)

ms.compute_texcoord_by_function_per_wedge()

ms.save_current_mesh(mesh_path + "pyProcessTest.obj",
                     save_wedge_texcoord = False,
                     save_wedge_normal = False,
                     save_vertex_coord  = True,
# keeps vertex normals anyway, despite not being a setting for it
                     )