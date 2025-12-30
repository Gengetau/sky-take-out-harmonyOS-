package com.sky.dto;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

import java.io.Serializable;

@Data
@ApiModel(description = "用户单一信息修改传递的数据模型")
public class UserEditDTO implements Serializable {

    @ApiModelProperty("要修改的字段名 (name/sex/profile/idNumber/phone)")
    private String code;

    @ApiModelProperty("新的值")
    private String value;
}
