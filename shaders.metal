struct RasterizerData
{
	float4 position [[position]];
	float4 color;
};

constant RasterizerData vertices[] = {
        {{0, 0.5, 0, 1}, {1, 0, 0, 1}},
        {{-0.5, -0.5, 0, 1}, {0, 1, 0, 1}},
        {{0.5, -0.5, 0, 1}, {0, 0, 1, 1}},
};

vertex RasterizerData
VertexFunction(uint vertex_id [[vertex_id]])
{
	return vertices[vertex_id];
}

fragment float4
FragmentFunction(RasterizerData input [[stage_in]])
{
	return input.color;
}
