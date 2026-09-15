package com.shawenterprise.web;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

/** Preserves generated image URLs stored by the previous catalog backend. */
@RestController
public class GeneratedImageController {
    @GetMapping(value = "/images/{name:generated-[a-zA-Z0-9-]+\\.svg}", produces = "image/svg+xml")
    public String image(@PathVariable String name) {
        var parts = name.split("-");
        var label = parts.length > 1 ? parts[1] : "Products";
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"640\" height=\"480\" viewBox=\"0 0 640 480\"><rect width=\"640\" height=\"480\" rx=\"24\" fill=\"#f4f0e5\"/><circle cx=\"320\" cy=\"210\" r=\"120\" fill=\"#e9b949\"/><circle cx=\"320\" cy=\"210\" r=\"94\" fill=\"#fffaf0\"/><text x=\"320\" y=\"390\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"32\" fill=\"#123432\">" + label + "</text></svg>";
    }
}
