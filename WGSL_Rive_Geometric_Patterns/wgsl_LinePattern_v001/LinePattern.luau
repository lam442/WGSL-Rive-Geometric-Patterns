type LinePattern = {
  thickness: Input<number>,
  spacing: Input<number>,
  angle: Input<number>,
  offset: Input<number>,
  canvasWidth: Input<number>,
  canvasHeight: Input<number>,
  lineColor: Input<Color>,

  canvas: GPUCanvas?,
  pipeline: GPUPipeline?,
  ubo: GPUBuffer?,
  bindGroup: GPUBindGroup?,
  staging: buffer,
  sampler: ImageSampler,
}

local function uploadUniforms(self: LinePattern)
  local ubo = self.ubo
  if not ubo then
    return
  end

  local s = self.staging
  buffer.writef32(s, 0, self.thickness)
  buffer.writef32(s, 4, self.spacing)
  buffer.writef32(s, 8, self.angle)
  buffer.writef32(s, 12, self.offset)

  local lc = Color.toFloat(self.lineColor)
  buffer.writef32(s, 16, lc[1])
  buffer.writef32(s, 20, lc[2])
  buffer.writef32(s, 24, lc[3])
  buffer.writef32(s, 28, lc[4])

  ubo:write(s)
end

function init(self: LinePattern, context: Context): boolean
  local shader = context:shader('LinePatternShader')
  if not shader then
    print('LinePatternShader not found!')
    return false
  end

  local w = math.max(1, math.floor(self.canvasWidth))
  local h = math.max(1, math.floor(self.canvasHeight))
  local canvas = context:gpuCanvas({ width = w, height = h })

  local pipeline = GPUPipeline.new({
    vertex = shader,
    fragment = shader,
    vertexLayout = {},
    colorTargets = {
      { format = canvas.format },
    },
  })

  local ubo = GPUBuffer.new({
    size = 32,
    usage = 'uniform',
  })

  local bindGroup = GPUBindGroup.new({
    layout = pipeline:getBindGroupLayout(0),
    ubos = {
      { slot = 0, buffer = ubo },
    },
  })

  self.canvas = canvas
  self.pipeline = pipeline
  self.ubo = ubo
  self.bindGroup = bindGroup

  uploadUniforms(self)
  return true
end

function update(self: LinePattern)
  local canvas = self.canvas
  if canvas then
    local w = math.max(1, math.floor(self.canvasWidth))
    local h = math.max(1, math.floor(self.canvasHeight))
    if canvas.width ~= w or canvas.height ~= h then
      canvas:resize(w, h)
    end
  end
  uploadUniforms(self)
end

function draw(self: LinePattern, renderer: Renderer)
  local canvas = self.canvas
  local pipeline = self.pipeline
  local bindGroup = self.bindGroup

  if not canvas or not pipeline or not bindGroup then
    return
  end

  local pass = canvas:beginRenderPass({
    color = {
      {
        loadOp = 'clear',
        storeOp = 'store',
        clearColor = { 0, 0, 0, 0 },
      },
    },
  })

  pass:setPipeline(pipeline)
  pass:setBindGroup(0, bindGroup)
  pass:draw(3)
  pass:finish()

  renderer:drawImage(canvas.image, self.sampler, 'srcOver', 1)
end

return function(): Node<LinePattern>
  return {
    thickness = 4,
    spacing = 32,
    angle = 0,
    offset = 0,
    canvasWidth = 800,
    canvasHeight = 800,
    lineColor = Color.rgba(0, 0, 0, 255),
    canvas = nil,
    pipeline = nil,
    ubo = nil,
    bindGroup = nil,
    staging = buffer.create(32),
    sampler = ImageSampler('clamp', 'clamp', 'bilinear'),
    init = init,
    update = update,
    draw = draw,
  }
end
