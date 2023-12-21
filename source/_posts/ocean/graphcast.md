---
title: GraphCast
date: 2023-11-21 23:09:32
tags:
- "Python"
id: graphcast
no_word_count: true
no_toc: false
categories: "Ocean"
---

## GraphCast

### 简介

GraphCast 是一种基于机器学习的天气预报方式，单纯使用数据进行训练和预测而不是采用当前数据进行计算。

### 使用方式

#### 原生样例

安装依赖：

```bash
pip install --upgrade https://github.com/deepmind/graphcast/archive/master.zip
pip uninstall -y shapely
yum install gcc gcc-c++ python3.11-devel epel-release -y
yum install geos geos-devel -y
pip install shapely --no-binary shapely
git clone https://github.com/deepmind/graphcast
cd graphcast
```

具体使用请参见 [Colab](https://colab.research.google.com/github/deepmind/graphcast/blob/master/graphcast_demo.ipynb)

在项目中可以找到 `graphcast.py` 文件，此文件即时程序运行的入口。可以参照如下代码运行程序获取预测数据：

```python
import dataclasses
import functools

from graphcast import autoregressive
from graphcast import casting
from graphcast import data_utils
from graphcast import graphcast
from graphcast import normalization
from graphcast import rollout
from graphcast import xarray_jax
from graphcast import xarray_tree
import haiku as hk
import jax
import numpy as np
import xarray


def parse_file_parts(file_name):
    return dict(part.split("-", 1) for part in file_name.split("_"))

def construct_wrapped_graphcast(
        model_config: graphcast.ModelConfig,
        task_config: graphcast.TaskConfig):
    """Constructs and wraps the GraphCast Predictor."""
    # Deeper one-step predictor.
    predictor = graphcast.GraphCast(model_config, task_config)

    # Modify inputs/outputs to `graphcast.GraphCast` to handle conversion to
    # from/to float32 to/from BFloat16.
    predictor = casting.Bfloat16Cast(predictor)

    # Modify inputs/outputs to `casting.Bfloat16Cast` so the casting to/from
    # BFloat16 happens after applying normalization to the inputs/targets.
    predictor = normalization.InputsAndResiduals(
        predictor,
        diffs_stddev_by_level=diffs_stddev_by_level,
        mean_by_level=mean_by_level,
        stddev_by_level=stddev_by_level)

    # Wraps everything so the one-step model can produce trajectories.
    predictor = autoregressive.Predictor(predictor, gradient_checkpointing=True)
    return predictor


@hk.transform_with_state
def run_forward(model_config, task_config, inputs, targets_template, forcings):
    predictor = construct_wrapped_graphcast(model_config, task_config)
    return predictor(inputs, targets_template=targets_template, forcings=forcings)


@hk.transform_with_state
def loss_fn(model_config, task_config, inputs, targets, forcings):
    predictor = construct_wrapped_graphcast(model_config, task_config)
    loss, diagnostics = predictor.loss(inputs, targets, forcings)
    return xarray_tree.map_structure(
        lambda x: xarray_jax.unwrap_data(x.mean(), require_jax=True),
        (loss, diagnostics))

def grads_fn(params, state, model_config, task_config, inputs, targets, forcings):
    def _aux(params, state, i, t, f):
        (loss, diagnostics), next_state = loss_fn.apply(
            params, state, jax.random.PRNGKey(0), model_config, task_config,
            i, t, f)
        return loss, (diagnostics, next_state)
    (loss, (diagnostics, next_state)), grads = jax.value_and_grad(
        _aux, has_aux=True)(params, state, inputs, targets, forcings)
    return loss, diagnostics, next_state, grads

# Jax doesn't seem to like passing configs as args through the jit. Passing it
# in via partial (instead of capture by closure) forces jax to invalidate the
# jit cache if you change configs.
def with_configs(fn):
    return functools.partial(
        fn, model_config=model_config, task_config=task_config)

# Always pass params and state, so the usage below are simpler
def with_params(fn):
    return functools.partial(fn, params=params, state=state)

# Our models aren't stateful, so the state is always empty, so just return the
# predictions. This is requiredy by our rollout code, and generally simpler.
def drop_state(fn):
    return lambda **kw: fn(**kw)[0]

if __name__ == "__main__":
    file = "xxxx.nc"
    params = None
    state = {}

    model_config = graphcast.ModelConfig(
        resolution=0,
        mesh_size=random_mesh_size.value,
        latent_size=random_latent_size.value,
        gnn_msg_steps=random_gnn_msg_steps.value,
        hidden_layers=1,
        radius_query_fraction_edge_length=0.6)
    task_config = graphcast.TaskConfig(
        input_variables=graphcast.TASK.input_variables,
        target_variables=graphcast.TASK.target_variables,
        forcing_variables=graphcast.TASK.forcing_variables,
        pressure_levels=graphcast.PRESSURE_LEVELS[random_levels.value],
        input_duration=graphcast.TASK.input_duration,
    )
    example_batch = xarray.load_dataset(file).compute()
    train_steps = 1
    eval_steps = 1

    train_inputs, train_targets, train_forcings = data_utils.extract_inputs_targets_forcings(
        example_batch, target_lead_times=slice("6h", f"{train_steps*6}h"),
        **dataclasses.asdict(task_config))
    eval_inputs, eval_targets, eval_forcings = data_utils.extract_inputs_targets_forcings(
        example_batch, target_lead_times=slice("6h", f"{eval_steps*6}h"),
        **dataclasses.asdict(task_config))

    print("All Examples:  ", example_batch.dims.mapping)
    print("Train Inputs:  ", train_inputs.dims.mapping)
    print("Train Targets: ", train_targets.dims.mapping)
    print("Train Forcings:", train_forcings.dims.mapping)
    print("Eval Inputs:   ", eval_inputs.dims.mapping)
    print("Eval Targets:  ", eval_targets.dims.mapping)
    print("Eval Forcings: ", eval_forcings.dims.mapping)

    with open ("stats/diffs_stddev_by_level.nc", "rb") as f:
        diffs_stddev_by_level = xarray.load_dataset(f).compute()
    with open ("stats/mean_by_level.nc", "rb") as f:
        mean_by_level = xarray.load_dataset(f).compute()
    with open ("stats/stddev_by_level.nc", "rb") as f:
        stddev_by_level = xarray.load_dataset(f).compute()
    init_jitted = jax.jit(with_configs(run_forward.init))

    if params is None:
        params, state = init_jitted(
            rng=jax.random.PRNGKey(0),
            inputs=train_inputs,
            targets_template=train_targets,
            forcings=train_forcings)

    loss_fn_jitted = drop_state(with_params(jax.jit(with_configs(loss_fn.apply))))
    grads_fn_jitted = with_params(jax.jit(with_configs(grads_fn)))
    run_forward_jitted = drop_state(with_params(jax.jit(with_configs(
        run_forward.apply))))

    assert model_config.resolution in (0, 360. / eval_inputs.sizes["lon"]), (
        "Model resolution doesn't match the data resolution. You likely want to "
        "re-filter the dataset list, and download the correct data.")

    print("Inputs:  ", eval_inputs.dims.mapping)
    print("Targets: ", eval_targets.dims.mapping)
    print("Forcings:", eval_forcings.dims.mapping)

    predictions = rollout.chunked_prediction(
        run_forward_jitted,
        rng=jax.random.PRNGKey(0),
        inputs=eval_inputs,
        targets_template=eval_targets * np.nan,
        forcings=eval_forcings)
```

> 注：由于不知道怎样构建其它数据的 stats 参数和模型，而且官方文档并未对这些内容进行详细说明，故需要找一下其他的方式。

#### Nvidia Modulus

Modulus 是一个开源的深度学习框架，用于使用最先进的物理ML方法构建、训练和微调深度学习模型。

在 Modulus 示例中有预先调整和下载的 GraphCast 样例。

安装环境：

```bash
git clone https://github.com/NVIDIA/modulus.git
cd modulus/examples/weather/graphcast
pip install nvidia-modulus matplotlib wandb netCDF4 scikit-learn
```

> 注：目前处于 Beta 阶段资料不全，项目运行时读取的静态文件部分没有说明，代码中的读取方式和样例数据不一致，依赖库没有完全安装，所以没有进行详细测试。

#### Graph Weather

Graph Weather 是一种使用 PyTorch 的开源实现。

安装环境：

> 注：此处需要首先访问 [官网](https://pytorch.org/get-started/locally/) 下载对应版本的 PyTorch，然后再安装其余内容。

```bash
git clone https://github.com/openclimatefix/graph_weather.git
pip install graph-weather
```




### 获取数据

> 注：此样例严格限制 Python 版本为 3.10。在演示中采用的具体版本是 3.10.13

ECMWF 提供了一个样例项目用于便捷的生成预测数据，安装方式如下：

```bash
pip install ai-models
pip install ai-models-graphcast
git clone https://github.com/ecmwf-lab/ai-models-graphcast.git 
cd ai-models-graphcast
```

如果使用 CPU 则需要使用如下命令：

```bash
pip install -r requirements.txt
```

如果使用 GPU 则需要使用如下命令：

```bash
pip install -r requirements-gpu.txt -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html
```

然后使用如下命令即可获取预测数据：

```bash
ai-models graphcast --date 20231214 --input cds --output file --download-assets
```

> 注：此程序需要从 [cds](https://cds.climate.copernicus.eu/) 获取数据，需要一个账号。(可以免费注册)

### 参考资料

[Learning skillful medium-range global weather forecasting 论文 ](https://www.science.org/stoken/author-tokens/ST-1550/full)

[GraphCast: AI model for faster and more accurate global weather forecasting 博客](https://deepmind.google/discover/blog/graphcast-ai-model-for-faster-and-more-accurate-global-weather-forecasting/)

[graphcast 官方项目](https://github.com/google-deepmind/graphcast)

[Colab (Notepad)](https://colab.research.google.com/github/deepmind/graphcast/blob/master/graphcast_demo.ipynb)

[GraphCast for weather forecasting(Modulus)](https://github.com/NVIDIA/modulus/tree/main/examples/weather/graphcast)

[Modulus Globus Files](https://app.globus.org/file-manager?origin_id=945b3c9e-0f8c-11ed-8daf-9f359c660fbd&origin_path=%2F)

[Graph Weather](https://github.com/openclimatefix/graph_weather)

[ai-models-graphcast](https://github.com/ecmwf-lab/ai-models-graphcast)
