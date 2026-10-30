type GridPattern = {
  thicknessX: Input<number>,
  thicknessY: Input<number>,
  spacingX: Input<number>,
  spacingY: Input<number>,
  offsetX: Input<number>,
  offsetY: Input<number>,
  canvasWidth: Input<number>,
  canvasHeight: Input<number>,
  gridColor: Input<Color>,

  canvas: GPUCanvas?,
  pipeline: GPUPipeline?,
  ubo: GPUBuffer?,
  bindGroup: GPUBindGroup?,
  staging: buffer,
  sampler: ImageSampler,
}

local function uploadUniforms(self: GridPattern)
  local ubo = self.ubo
  if not ubo then
    return
  end

  local s = self.staging
  buffer.writef32(s, 0, self.thicknessX)
  buffer.writef32(s, 4, self.thicknessY)
  buffer.writef32(s, 8, self.spacingX)
  buffer.writef32(s, 12, self.spacingY)
  buffer.writef32(s, 16, self.offsetX)
  buffer.writef32(s, 20, self.offsetY)
  buffer.writef32(s, 24, 0)
  buffer.writef32(s, 28, 0)

  local gc = Color.toFloat(self.gridColor)
  buffer.writef32(s, 32, gc[1])
  buffer.writef32(s, 36, gc[2])
  buffer.writef32(s, 40, gc[3])
  buffer.writef32(s, 44, gc[4])

  ubo:write(s)
end

function init(self: GridPattern, context: Context): boolean
  local shader = context:shader('GridPatternShader')
  if not shader then
    print('GridPatternShader not found!')
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
    size = 48,
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

function update(self: GridPattern)
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

function draw(self: GridPattern, renderer: Renderer)
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

return function(): Node<GridPattern>
  return {
    thicknessX = 2,
    thicknessY = 2,
    spacingX = 32,
    spacingY = 32,
    offsetX = 0,
    offsetY = 0,
    canvasWidth = 800,
    canvasHeight = 800,
    gridColor = Color.rgba(0, 0, 0, 255),
    canvas = nil,
    pipeline = nil,
    ubo = nil,
    bindGroup = nil,
    staging = buffer.create(48),
    sampler = ImageSampler('clamp', 'clamp', 'bilinear'),
    init = init,
    update = update,
    draw = draw,
  }
end
