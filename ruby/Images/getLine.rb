require 'chunky_png'

# pixel chi la diem bien khi no thoa cac dieu kien sau 
# 
def check2(x,y)
	max_count = 0
	nexti = nil
	nextj = nil
	for i in x-1..x+1
		if i < 0 
			next
		end

		for j in y-1..y+1
			if j < 0
				next
			end
			if (i == x && j == y) then
				next
			end

			if (ChunkyPNG::Color.a($image[i,j]) == 255) then
				cnt = check1(i,j)
				if (max_count < cnt) then
					max_count = cnt
					nexti = i
					nextj = j
				end
			end
		end
	end
	puts("Next point : x = #{nextj}, y = #{nextj}")
end

def check1(x,y)
	count = 0
	for i in x-1..x+1
		for j in y-1..y+1
			if (i >= 0 && j >= 0) then
				if (ChunkyPNG::Color.a($image[i,j]) != 255) then
					count = count + 1
				end
			end
		end
	end
	return count
end

$image = ChunkyPNG::Image.from_file('stage6.png')
puts $image.dimension.height
puts $image.dimension.width
$i = 0
while ($i <= $image.dimension.height)
	if (ChunkyPNG::Color.a($image[$i,1]) == 255) then
		puts("x = #{$i} , alpha = #{ChunkyPNG::Color.a($image[$i,1])}\n")
		check2($i,1)
		break
	end
	$i +=1
end