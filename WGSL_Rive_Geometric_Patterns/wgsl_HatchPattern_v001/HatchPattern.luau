type HatchPattern = {
  thicknessA: Input<number>,
  thicknessB: Input<number>,
  spacingA: Input<number>,
  spacingB: Input<number>,
  angleA: Input<number>,
  angleB: Input<number>,
  offsetA: Input<number>,
  offsetB: Input<number>,
  canvasWidth: Input<number>,
  canvasHeight: Input<number>,
  hatchColor: Input<Color>,

  canvas: GPUCanvas?,
  pipeline: GPUPipeline?,
  ubo: GPUBuffer?,
  bindGroup: GPUBindGroup?,
  staging: buffer,
  sampler: ImageSampler,
}

local function uploadUniforms(self: HatchPattern)
  local ubo = self.ubo
  if not ubo then
    return
  end

  local s = self.staging
  buffer.writef32(s, 0, self.thicknessA)
  buffer.writef32(s, 4, self.thicknessB)
  buffer.writef32(s, 8, self.spacingA)
  buffer.writef32(s, 12, self.spacingB)
  buffer.writef32(s, 16, self.angleA)
  buffer.writef32(s, 20, self.angleB)
  buffer.writef32(s, 24, self.offsetA)
  buffer.writef32(s, 28, self.offsetB)

  local hc = Color.toFloat(self.hatchColor)
  buffer.writef32(s, 32, hc[1])
  buffer.writef32(s, 36, hc[2])
  buffer.writef32(s, 40, hc[3])
  buffer.writef32(s, 44, hc[4])

  ubo:write(s)
end

function init(self: HatchPattern, context: Context): boolean
  local shader = context:shader('HatchPatternShader')
  if not shader then
    print('HatchPatternShader not found!')
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

function update(self: HatchPattern)
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

function draw(self: HatchPattern, renderer: Renderer)
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

return function(): Node<HatchPattern>
  return {
    thicknessA = 2,
    thicknessB = 2,
    spacingA = 32,
    spacingB = 32,
    angleA = 45,
    angleB = -45,
    offsetA = 0,
    offsetB = 0,
    canvasWidth = 800,
    canvasHeight = 800,
    hatchColor = Color.rgba(0, 0, 0, 255),
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
