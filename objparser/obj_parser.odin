package obj_parser

import "../mesh"
import "core:bufio"
import "core:os"
import "core:strings"
import "core:fmt"
import "core:strconv"

//do per scontato alcune cose, tra cui che i vertici abbiano 3 coordinate 
//AKA il parser supporta per ora solo obj con triangles e codificati come Quads

load_obj_file_data :: proc (filepath : string, my_mesh : ^mesh.mesh_t) {


	//percorri il file stringa by string 
	//vedi se e' f o v o altro 
	//riempi la struct mesh di conseguenza con quello che interessa per ora  
	data, ok := os.read_entire_file(filepath, context.allocator)
	if !ok {
		// could not read file
		fmt.eprintf("could not read file!")
		return
	}
	defer delete(data, context.allocator)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		// process line
		//se carattere e' v e dopo nulla, il resto fino a newline diviso per spazi va immagazzinato in mesh.
		//mesh.vertices
		//se il carattere e' f 
		// la linea va immagazzinata in f[i].
		if strings.contains(line, "v "){

			local, ok:= strings.remove(line, "v ", 1)
			if !ok {
				fmt.eprintf("error removing V from obj file line ")
				return 
			}
						
			extrapolated_values := strings.split(local, " ")
	
			numbers : mesh.Vector3_t

			numbers.x = f32(strconv.atof(extrapolated_values[0]))
			
			numbers.y = f32(strconv.atof(extrapolated_values[1]))

			numbers.z = f32(strconv.atof(extrapolated_values[2]))

			//pusha e fai crescere array di vertici della struct mesh 
			append(&my_mesh.vertices, numbers)	

		}
		//stessa cosa per f 
		if strings.contains(line, "f "){



			local, ok:= strings.remove(line, "f ", 1)
			if !ok {
				fmt.eprintf("error removing F from obj file line ")
				return 
			}

			splits := [?]string { " ", "/" }


			extrapolated_multi := strings.split_multi(local, splits[:])


			//0, 3, 6 sono gli indici che ci interessano da trasformare di ogni sottostringa
			temp_face : mesh.Face_t
			temp_tex : mesh.Texture_indices_t
			temp_norm : mesh.Normal_indices_t
			for i := 0; i < len(extrapolated_multi); i+=1 {
        		

        		if i == 0 {
        		temp_face[0] = strconv.atoi(extrapolated_multi[i])
        		}
        		else if i == 3 {
        			temp_face[1] = strconv.atoi(extrapolated_multi[i])
        		} else if i == 6 {
        			temp_face[2] = strconv.atoi(extrapolated_multi[i])
        		}

        		if i == 1 {
        				temp_tex[0] = strconv.atoi(extrapolated_multi[i])
        		} else if i == 4 {
        				temp_tex[1] = strconv.atoi(extrapolated_multi[i])
        		} else if i == 7{
        				temp_tex[2] = strconv.atoi(extrapolated_multi[i])
        		}


        		if i == 2 {
        					temp_norm[0] = strconv.atoi(extrapolated_multi[i])
        		} else if i == 5{
        					temp_norm[1] = strconv.atoi(extrapolated_multi[i])

        		} else if i == 8{
        				   temp_norm[2] = strconv.atoi(extrapolated_multi[i])

        		}



   			 }

   			append(&my_mesh.faces, temp_face)
   			append(&my_mesh.tex_indices, temp_tex)
   			append(&my_mesh.norm_indices, temp_norm)


		}

		//TODO successiva -> fare la stessa cosa per vt e per vn normali e texture 

	}



}