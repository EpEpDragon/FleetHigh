extends Node

func zero_matrix(nX, nY) -> Array:
	var matrix = []
	for x in range(nX):
		matrix.append([])
		for y in range(nY):
			matrix[x].append(0)
	return matrix


func add(a, b) -> Array:
	var matrix = zero_matrix(a.size(), a[0].size())	
	for i in range(a.size()):
		for j in range(a[0].size()):
			matrix[i][j] = a[i][j] + b[i][j]
	return matrix


func subtract(a, b) -> Array:
	var matrix = zero_matrix(a.size(), a[0].size())	
	for i in range(a.size()):
		for j in range(a[0].size()):
			matrix[i][j] = a[i][j] - b[i][j]
	return matrix


func multiply(a, b) -> Array:
	var matrix = zero_matrix(a.size(), b[0].size())
	for i in range(a.size()):
		for j in range(b[0].size()):
			for k in range(a[0].size()):
				matrix[i][j] = matrix[i][j] + a[i][k] * b[k][j]
	return matrix

