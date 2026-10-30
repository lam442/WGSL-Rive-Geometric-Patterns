type RadialPattern = {
  centerX: Input<number>,
  centerY: Input<number>,
  ringSpacing: Input<number>,
  ringThickness: Input<number>,
  rayCount: Input<number>,
  rayThickness: Input<number>,
  rotation: Input<number>,
  canvasWidth: Input<number>,
  canvasHeight: Input<number>,
  radialColor: Input<Color>,

  canvas: GPUCanvas?,
  pipeline: GPUPipeline?,
  ubo: GPUBuffer?,
  bindGroup: GPUBindGroup?,
  staging: buffer,
  sampler: ImageSampler,
}

local function uploadUniforms(self: RadialPattern)
  local ubo = self.ubo
  if not ubo then
    return
  end

  local s = self.staging
  buffer.writef32(s, 0, self.centerX)
  buffer.writef32(s, 4, self.centerY)
  buffer.writef32(s, 8, self.ringSpacing)
  buffer.writef32(s, 12, self.ringThickness)
  buffer.writef32(s, 16, self.rayCount)
  buffer.writef32(s, 20, self.rayThickness)
  buffer.writef32(s, 24, self.rotation)
  buffer.writef32(s, 28, 0)

  local rc = Color.toFloat(self.radialColor)
  buffer.writef32(s, 32, rc[1])
  buffer.writef32(s, 36, rc[2])
  buffer.writef32(s, 40, rc[3])
  buffer.writef32(s, 44, rc[4])

  ubo:write(s)
end

function init(self: RadialPattern, context: Context): boolean
  local shader = context:shader('RadialPatternShader')
  if not shader then
    print('RadialPatternShader not found!')
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

function update(self: RadialPattern)
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

function draw(self: RadialPattern, renderer: Renderer)
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

return function(): Node<RadialPattern>
  return {
    centerX = 400,
    centerY = 400,
    ringSpacing = 32,
    ringThickness = 2,
    rayCount = 12,
    rayThickness = 2,
    rotation = 0,
    canvasWidth = 800,
    canvasHeight = 800,
    radialColor = Color.rgba(0, 0, 0, 255),
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
